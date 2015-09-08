module rbf.format;

import std.stdio;
import std.file;
import std.string;
import std.xml;
import std.conv;
import std.exception;

import rbf.field;
import rbf.record;


/***********************************
 * This class build the list of records and fields from an XML definition file
 */
class Format {

private:

	/// used to hold record definition as build from XML file
	Record[string] _records;

	// description as found is the XML main tag
	string _description;

public:
	/**
	 * create all records based on the XML file structure
	 *
	 * Params:
	 *	xmlFile = name of the record/field definition list
	 *
	 * Examples:
	 * --------------
	 * auto fmt = new Format("my_def_file.xml");
	 * --------------
	 */
	this(string xmlFile)
	{
		// check for XML file existence
		enforce(exists(xmlFile), "XML definition file %s not found".format(xmlFile));


		string[string] fd;		/// associative array to hold field data
		string recName = "";		/// to save the record name when we find a <record> tag


		// open XML file and load it into a string
		string s = cast(string)std.file.read(xmlFile);

		// create a new parser
		auto xml = new DocumentParser(s);

		// save descrpition of the structure
		_description = xml.tag.attr["description"];

		// read <record> definitions and create record object
		xml.onStartTag["record"] = (ElementParser xml)
		{
			// save record name
			recName = xml.tag.attr["name"];

			// create Record object and store it into our record aa
			_records[recName] = new Record(recName, xml.tag.attr["description"]);
		};

		// read <field> definitions, create field and add field to previously created record
		xml.onStartTag["field"] = (ElementParser xml)
		{
			// fetch field name
			auto field = new Field(
				xml.tag.attr["name"],
				xml.tag.attr["description"],
				xml.tag.attr["type"],
				to!uint(xml.tag.attr["length"])
			);

			// add field to our record
			_records[recName] ~= field;
		};


		xml.parse();
	}

	/**
	 * array of all records
	 */
	@property Record[string] records() { return _records; }

	/**
	 * description of the XML structure
	 */
	@property string description() { return _description; }



	/**
	 * [] operator to retrieve the record by name
	 *
	 * Params:
	 * 	recName = name of the record to retrieve
	 *
	 */
	ref Record opIndex(string recName)
	{
		return _records[recName];
	}

}

unittest {
	writefln("-------------------------------------------------------------");
	writeln(__FILE__);
	writefln("-------------------------------------------------------------");

	auto f = new Format("../test/world_data.xml");

	foreach (string s, Record rec; f.records)
	{
		writeln(rec);
	}
}
