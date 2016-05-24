module rbf.builders.xmltextbuilder;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.xml;
import std.conv;
import std.exception;
import std.algorithm;
import std.regex;
import std.array;
import std.path;

import rbf.errormsg;
import rbf.log;
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.builders.xmlcore;
import rbf.builders.xmlbuilder;
//import rbf.layout;

// useful structs for holding sanitizing options

class RbfTextBuilder : RbfBuilder
{
    File _fh;           // file handle on file to read and scan

    //RbfBuilder builder; // main helper to build XML 

    /*
    struct
    {
        string inputFile, outputFile;
    }
    */
    string inputFile;           /// input file to process
    string meta;                /// meta tag as found in the file
    string orphanMode;          /// option to manage orphan

    Sanitizer[string][string] sanitizer;

    // read xmlFile to fetch configuration definition
    this(string xmlFile)
    {
        // create new builder
        //builder = new RbfBuilder();

		// check for XML file existence
		enforce(exists(xmlFile), MSG088.format(xmlFile));

		// open XML file and load it into a string
		string xmlData = cast(string)std.file.read(xmlFile);

		// create a new parser
		auto xml = new DocumentParser(xmlData);

		// read meta
		xml.onStartTag["meta"] = (ElementParser xml)
		{
            // save meta tag verbatim
            meta = xml.tag.toString;
        };

		// read file <input> definitions and keep types
		xml.onStartTag["input"] = (ElementParser xml)
		{
            // save input file
            inputFile = xml.tag.attr.get("file", "");
        };

        /*
		// read file <output> definitions and keep types
		xml.onStartTag["output"] = (ElementParser xml)
		{
            // save input file
            outputFile = xml.tag.attr.get("file", "");
        };
        */

		// read file <recordregex> definitions and keep types
		xml.onStartTag["recordregex"] = (ElementParser xml)
		{
            // set regex on builder
            this.recordRegex = xml.tag.attr.get("expr", "");
        };

		// read file <fieldregex> definitions and keep types
		xml.onStartTag["fieldregex"] = (ElementParser xml)
		{
            // set regex on builder
            this.fieldRegex = xml.tag.attr.get("expr", "");
        };

		// read file <orphan> definitions and keep types
		xml.onStartTag["orphan"] = (ElementParser xml)
		{
            // copy orphan option
             orphanMode = xml.tag.attr.get("mode", "");
        };

        // manage sanitizer options
		xml.onStartTag["attribute"] = (ElementParser xml)
		{
            // field sanitizer options (ElementParser xml)
            auto tag = xml.tag.attr["tag"];
            auto attr = xml.tag.attr["name"];

            // process sanitizer options from <sanitizer> tag
            Sanitizer s;
            foreach (option;  xml.tag.attr["options"].split(",").map!(e => e.strip))
            {
                // regex when using replace option
                string regexes;

                // replace attribute is special. Need to manage = sign
                auto indexOfEqual = option.indexOf('=');
                if (indexOfEqual != -1)
                {
                    regexes = option[indexOfEqual+1..$];
                    option = option[0..indexOfEqual];
                }

                switch(option)
                {
                    case "strip":
                        s.strip = true;
                        break;
                    case "capitalize":
                        s.capitalize = true;
                        break;
                    case "uppercase":
                        s.uppercase = true;
                        break;
                    case "replace":
                        foreach (t; regexes.split(";"))
                        {
                            auto rep = t.split(":");
                            s.replaceRegex ~= rep;
                        }
                        break;
                    default:
                        log.error(MSG056, option, tag, attr);
                        break;
                }
            }

            // add option
            sanitizer[tag][attr] = s;
        };


		// real XML parsing occurs here
		xml.parse();
    }

    // process input file
    void processInputFile()
    {
        // data coming from either record or field data
        string[string] data;

        // list of records and fields
        Record[] recList;

        // list of created field types
        FieldType[string] ftype;

		// check for XML file existence
		enforce(exists(inputFile), MSG089.format(inputFile));

        // process each of the input file
        foreach (string line; lines(File(inputFile, "r")))
        {
            // strip lines
            line = line.strip;

            // ignore empty lines
            if (line == "") continue;

            // record?
            data = this.isRecordMatched(line);
            if (data != null)
            {
                // first, sanitize data according to options
                _sanitizeData(data, "record");

                // add record to list
                recList ~= new Record(data);
                continue;
            }

            // field?
            data = this.isFieldMatched(line);
            if (data != null)
            {
                // first, sanitize data according to options
                _sanitizeData(data, "field");

                // add field to last record added
                recList[$-1] ~= new Field(data);

                // create new field type if not already existing
                auto type = data["type"];
                if (type !in ftype)
                {
                    switch(type)
                    {
                        case "AN":
                        case "A/N":
                        case "CHAR":
                            ftype[type] = new FieldType(type, "string");
                            break;
                        case "I":
                            ftype[type] = new FieldType(type, "integer");
                            break;
                        case "N":
                        case "NUM":
                        case "NUMC":
                            ftype[type] = new FieldType(type, "decimal");
                            break;
                        default:
                            ftype[type] = new FieldType(type, "string");
                            break;
                    }
                }
                continue;
            }

            // otherwise, manage orphans
            if (orphanMode == "post" && recList.length != 0)
            {
                // append this line to last field description
                Field lastField = recList[$-1][].back;
                lastField.description = lastField.description ~ " " ~ line.strip;
            }

        }

        // now we have all to build XML

        // build XML header
        writeln(`<?xml version="1.0" encoding="UTF-8"?>
<rbfile
    xmlns="http://www.w3schools.com"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.w3schools.com rbf.xsd"
>
`);
        // write meta tag verbatim
        writeln(meta);
        writeln;

        ftype.each!(ft => writeln(ft.asXML));
        writeln;

        // print out records
        recList.each!(r => writefln("%s\n", r.asXML));

        // end up XML
        writeln("</rbfile>");
    }

 private:
    void _sanitizeData(string[string] data, string tag)
    {
        if (tag in sanitizer)
        {
            foreach (attr; data.byKey)
            {
                if (attr in sanitizer[tag])
                {
                    data[attr] = sanitizer[tag][attr].sanitize(data[attr]);
                }
            }
        }
    }

}
    
///
unittest {
    auto r = new RbfTextBuilder("./test/catconf.xml");
    r.processInputFile;
}

