module rbf.format;

import std.stdio;
import std.file;
import std.string;
import std.xml;
import std.conv;
import std.exception;

import rbf.field;
import rbf.record;


class Format {
	
private:

	Record[string] _records;
	
public:

	/**
	 * create all records based on the XML file structure
	 */
	this(string xmlFile) 
	{
		
		enforce(exists(xmlFile), "XML definition file %s not found".format(xmlFile));				

		
		string[string] fd;		/// associative array to hold field data
		string recName = "";			/// to save the record name when we find a <record> tag
		string recDesc = "";
		string recType = "";
		
		FieldType[string] fieldTypes;
		
		
		// open XML file and load it into a string
		string s = cast(string)std.file.read(xmlFile);
		
		// create a new parser
		auto xml = new DocumentParser(s);
		
		// read <record> definitions and create record object
		xml.onStartTag["record"] = (ElementParser xml)
		{
			// fetch attributes
			recName = xml.tag.attr["name"];
			recDesc = xml.tag.attr["description"];
			
			// create Record object and store it into our record aa
			_records[recName] = new Record(recName, recDesc);
		};
		
		// read <field> definitions, create field and add field to record
		xml.onStartTag["field"] = (ElementParser xml)
		{
			// fetch field name
			auto field = new Field(
				xml.tag.attr["name"],
				xml.tag.attr["description"],
				xml.tag.attr["type"],
				to!uint(xml.tag.attr["length"])
			);
			
			_records[recName] ~= field;
		};
		
		
		xml.parse();
	
	}
	
	/**
	 * list of all records
	 */		
	@property Record[string] records() { return _records; }
	
	/**
	 * [] operator to retrieve the record by name
	 *
	 * Params:
	 * 	recordName = name of the record to retrieve
	 * 
	 */	
	ref Record opIndex(string recName) 
	{
		//writefln("recname=<%s>", recName);
		return _records[recName];
	}
	
}

unittest {
	auto f = new Format(r"/home/m330421/data/local/xml/hot203.xml");
	
	foreach (string s, Record rec; f.records)
	{
		writeln(rec);
	}
}
