module rbf.layout;

import std.stdio;
import std.file;
import std.string;
import std.xml;
import std.conv;
import std.exception;
import std.algorithm;

import rbf.field;
import rbf.record;


/***********************************
 * This class build the list of records and fields from an XML definition file
 */
class Layout {

private:

	/// used to hold record definition as build from XML file
	Record[string] _records;

	// description as found is the XML <rbfile> tag
	string _description;

	// length if found is <rbfile> table
	ulong _length;

public:
	/**
	 * create all records based on the XML file structure
	 *
	 * Params:
	 *	xmlFile = name of the record/field definition list
	 *
	 * Examples:
	 * --------------
	 * auto layout = new Layout("my_def_file.xml");
	 * --------------
	 */
	this(string xmlFile)
	{
		// check for XML file existence
		enforce(exists(xmlFile), "XML definition file %s not found".format(xmlFile));


		string[string] fd;		/// associative array to hold field data
		string recName = "";	/// to save the record name when we find a <record> tag


		// open XML file and load it into a string
		string s = cast(string)std.file.read(xmlFile);

		// create a new parser
		auto xml = new DocumentParser(s);

		// save description of the structure
		_description = xml.tag.attr["description"];

		// save length if any
		if ("reclength" in xml.tag.attr) {
			_length = to!ulong(xml.tag.attr["reclength"]);
		}

		// read <record> definitions and create a new record object
		xml.onStartTag["record"] = (ElementParser xml)
		{
			// save record name
			recName = xml.tag.attr["name"];

			// create a Record object and store it into our record aa
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
	 * description of the XML structure
	 */
	@property ulong length() { return _length; }

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

	/**
	 * to loop with foreach loop on all records of the layout
	 *
	 */
	 /*
	 @property bool empty() const { return _records.length == 0; }
	 @property ref Layout front() { return _records[0]; }
	 void popFront() { _records = _records[1..$]; }*/

 	/**
	 * to loop with foreach loop on all records of the layout
	 *
	 */
	int opApply(int delegate(ref Record) dg)
	{
		int result = 0;

		foreach (recName; sort(_records.keys)) {
				result = dg(_records[recName]);
				if (result)
			break;
		}
		return result;
	}

	/**
	 * record definition for all records found
	 *
	 */
	override string toString() {
		string s;
		foreach (rec; this) {
			s ~= rec.toString;
		}
		return s;
	}

	/**
	 * keep only fields specified for each record in the map
	 *
	 * Params:
	 *	recordMap = associate array (key=record name, value=array of field names)
	 *
	 * Examples:
	 * --------------
	 * recList["RECORD1"] = ["FIELD1", "FIELD2"];
	 * layout.prune(recList);
	 * --------------
	 */
	void prune(string[][string] recordMap) {
			// recordMap contains a list of fields to keep in each record
			// the key of recordMap is a record name
			// for all those records, keep only those provided
			foreach (rec; _records) {
				// recname is not concerned
				if (rec.name in recordMap) {
					// keep only those found
					if (recordMap[rec.name] != [])
						_records[rec.name].keepOnly(recordMap[rec.name]);
 				}
				else {
					// but we want all other not requested to not be kept
					_records[rec.name].keep = false;
				}
			}
	}



}

unittest {
	writefln("-------------------------------------------------------------");
	writeln(__FILE__);
	writefln("-------------------------------------------------------------");

	auto layout = new Layout("./test/world_data.xml");

	foreach (rec; layout)
	{
		writeln(rec);
	}

	//core.stdc.stdlib.exit(0);
}
