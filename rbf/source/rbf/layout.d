module rbf.layout;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.xml;
import std.conv;
import std.exception;
import std.algorithm;

import rbf.field;
import rbf.record;

version(unittest) {
	immutable test_file = "./test/world_data.xml";
}


/***********************************
 * This class build the list of records and fields from an XML definition file
 */
class Layout {

private:

	Record[string] _records;			/// used to hold record definition as build from XML file
	string _description;					/// description as found is the XML <rbfile> tag
	ulong _length;								/// length if found is <rbfile> table

public:
	/**
	 * create all records based on the XML file structure
	 *
	 * Params:
	 *	xmlFile = name of the record/field definition list
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
	///
	unittest {
		auto l = new Layout(test_file);
		assertThrown(new Layout("foo.xml"));
	}

	/**
	 * associative array of all records
	 */
	@property Record[string] records() { return _records; }

	/**
	 * string description of the XML structure
	 */
	@property string description() { return _description; }
	///
	unittest {
		auto l = new Layout(test_file);
		assert(l.description == "Continents, countries, cities");
	}

	/**
	 * length of each record of the XML structure
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
	///
	unittest {
		auto l = new Layout(test_file);
		assert(l.records.length == 2);
		assert(l["CONT"].name == "CONT");
		assert(l["COUN"].description == "Country data");
	}

	/**
	 * test if a field name is present in layout (== in all records)
	 *
	 * Params:
	 * 	fieldName = name of the field to look for
	 *
	 */
	Field[]* opBinaryRight(string op)(string fieldName)
	{
		static if (op == "in") {
			// loop on all records to search for this field
			foreach (rec; this) {
				auto f = fieldName in rec;
				if (f) return f;
			}

			// nothing found at this point
			return null;
		}
	}
	///
	unittest {
		auto l = new Layout(test_file);
		assert("CAPITAL" in l);
		assert("POPULATION" in l);
		assert("FOO" !in l);
	}

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
	 * layout.prunePerRecords(recList);
	 * --------------
	 */
	void keepOnly(string[][string] recordMap) {
			// recordMap contains a list of fields to keep in each record
			// the key of recordMap is a record name
			// for all those records, keep only those fields provided
			foreach (e; recordMap.byKeyValue) {
				_records[e.key].keepOnly(e.value);
			}

			// for all other records non provided, just get rid of them
			_records.byKey
							.filter!(e => e !in recordMap)
							.each!(e => _records[e].keep = false);
	}
	///
	unittest {
		auto l = new Layout(test_file);
		l.keepOnly(["CONT": ["NAME", "POPULATION"], "COUN": ["CAPITAL"]]);
		assert(l["CONT"] == ["NAME", "POPULATION"]);
		assert(l["COUN"] == ["CAPITAL"]);
	}

	/**
	 * for each record, remove each field not in the list. If field
	 * is not in the record, just loop
	 *
	 * Params:
	 *	fieldList = list of fields to get rid of
	 */
	void removeFromAllRecords(string[] fieldList) {
		_records.each!(r => r.remove(fieldList));
	}
	///
	unittest {
		auto l = new Layout(test_file);
		l.removeFromAllRecords(["ID", "NAME", "POPULATION"]);
		assert(l["CONT"] == ["AREA", "DENSITY", "CITY"]);
		assert(l["COUN"] == ["CAPITAL"]);
	}

	/**
	 * validate syntax: check if record length is matching file length
	 * is not in the record, just loop
	 */
	void validate() {
		foreach (rec; this) {
			if (rec.length != _length) {
				stderr.writefln("record %s is not matching declared length (%d instead of %d)",
					rec.name, rec.length, _length);
			}

			writeln(rec.toXML);
		}
	}


}
