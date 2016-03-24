module rbf.writers.xsdwriter;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.path;
import std.xml;

import rbf.errormsg;
import rbf.log;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;

immutable xmlField       = `<%s>%s</%s>`;
immutable xmlBeginRecord = `<RECORD_%s>`;
immutable xmlEndRecord   = `</RECORD_%s>`;

/*********************************************
 * writer class for writing to various ouput
 * formats
 */
class XmlWriter : Writer {

string _xsdFileName;
File _xsd;

	this(in string outputFileName)
	{
		super(outputFileName);

        // create XSD file
        _xsdFileName = stripExtension(outputFileName) ~ ".xsd";
        _xsd = File(_xsdFileName, "w");
        log.log(LogLevel.INFO, MSG019, _xsdFileName);

        // prepare XML file header
        _fh.writeln(`<?xml version="1.0" encoding="UTF-8" ?>`);
        _fh.writefln(`<rbfile
	xmlns="http://www.w3schools.com"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.w3schools.com %s">`, _xsdFileName);

        // create XSD header
        _xsd.writeln(`<?xml version="1.0" encoding="UTF-8" ?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
    targetNamespace="http://www.w3schools.com"
    xmlns="http://www.w3schools.com"
    elementFormDefault="qualified">`);
	}


    // preparing layout means here create an XSD schema from layout
	override void prepare(Layout layout) 
    {
        // layout has all definitions for records and fields. So we use those to define an XSD schema
        foreach (rec; layout)
        {
            // build XSD for fields
            /*
            foreach (f; rec)
            {
                _xsd.writefln(`<xs:element name="%s" type="xs:%s"/>`, f.name, f.type.meta.stringType);
            }
            */
            // now fields has been defined, ok for records
            _xsd.writefln(`<xs:element name="RECORD_%s"><xs:complexType><xs:sequence>`, rec.name);
            rec.each!(f => _xsd.writefln(`<xs:element name="%s" type="xs:%s"/>`, f.name, f.type.meta.stringType)); 
            _xsd.writefln(`</xs:sequence></xs:complexType></xs:element>`);
        }

        // now <rbfile> XML definition for whole file
        _xsd.writefln(`<xs:element name="rbfile"><xs:complexType><xs:sequence>`);
        layout.each!(rec => _xsd.writefln(`<xs:element ref="RECORD_%s" minOccurs="0" maxOccurs="unbounded"/>`, rec.name)); 
        _xsd.writefln(`</xs:sequence></xs:complexType></xs:element>`);
    }

    override void build(string outputFileName) {}

    // write out data as XML tree
	override void write(Record rec)
	{
        _fh.writefln(xmlBeginRecord, rec.name);
        foreach (f; rec)
        {
            _fh.writefln(xmlField, f.name, f.value.encode, f.name);
        }
        _fh.writefln(xmlEndRecord, rec.name, rec.value);
	}

	override void close()
	{
        // end up XSD
        _xsd.write("</xs:schema>");
		_xsd.close;

        // end up XML file
        _fh.write("</rbfile>");
        super.close;
	}
}
