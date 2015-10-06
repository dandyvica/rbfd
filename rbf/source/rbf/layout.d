module rbf.layout;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.xml;
import std.conv;
import std.exception;
import std.algorithm;

import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.nameditems;

version(unittest) {
	immutable test_file = "./test/world_data.xml";
	immutable test_file_fieldtype = "./test/world_data_with_types.xml";
}


/***********************************
 * This class build the list of records and fields from an XML definition file
 */
class Layout : NamedItemsContainer!(Record,false) {

private:
	FieldType[string] ftype;

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


		string recName = "";	/// to save the record name when we find a <record> tag


		// open XML file and load it into a string
		string s = cast(string)std.file.read(xmlFile);

		// create a new parser
		auto xml = new DocumentParser(s);

		// save metadata of the structure
		description = xml.tag.attr["description"];
		name = std.path.baseName(xmlFile);

		// save length if any
		if ("reclength" in xml.tag.attr) {
			_length = to!ulong(xml.tag.attr["reclength"]);
		}

		// read <fieldtype> definitions and keep types
		xml.onStartTag["fieldtype"] = (ElementParser xml)
		{
			// save record name
			auto ftName = xml.tag.attr["name"];
			auto type = xml.tag.attr["type"];

			// save field type base on its name
			ftype[ftName] = new FieldType(ftName, toLower(type));

			// pattern is optional
			string pattern;
			if ("pattern" in xml.tag.attr) {
				pattern = xml.tag.attr["pattern"];
				ftype[ftName].pattern = pattern;
			}
		};

		// read <record> definitions and create a new record object
		xml.onStartTag["record"] = (ElementParser xml)
		{
			// save record name
			recName = xml.tag.attr["name"];

			// create a Record object and store it into our record aa
			this  ~= new Record(recName, xml.tag.attr["description"]);
		};

		// read <field> definitions, create field and add field to previously created record
		xml.onStartTag["field"] = (ElementParser xml)
		{
			// fetch field type
			auto type = xml.tag.attr["type"];

			// already existing type from <fieldtype> ?
			Field field;
			if (type in ftype) {
					field = new Field(
						xml.tag.attr["name"],
						xml.tag.attr["description"],
						ftype[type],
						to!uint(xml.tag.attr["length"])
					);
			}
			// otherwise just create with fetched type
			else
				field = new Field(
					xml.tag.attr["name"],
					xml.tag.attr["description"],
					xml.tag.attr["type"],
					to!uint(xml.tag.attr["length"])
				);

			// add field to our record
			this[recName] ~= field;
		};


		xml.parse();
	}
	///
	unittest {
		auto l = new Layout(test_file);
		assertThrown(new Layout("foo.xml"));
	}

	///
	unittest {
		auto l = new Layout(test_file);
		assert("COUN" in l);
		assert("CONT" in l);
		assert("FOO" !in l);

		l = new Layout(test_file_fieldtype);
		assert("COUN" in l);
		assert("CONT" in l);
		assert("FOO" !in l);
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
				this[e.key].keepOnly(e.value);
			}

			// for all other records not provided, just get rid of them
			this[].filter!(e => e.name !in recordMap).each!(e => e.keep = false);
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
		this[].each!(r => r.remove(fieldList));
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

			//writeln(rec.toXML);
		}
	}


}
