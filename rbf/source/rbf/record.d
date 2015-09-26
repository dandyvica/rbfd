/**
 * Authors: Alain Viguier
 * Date: 03/04/2015
 * Version: 0.3
 */
module rbf.record;

import std.stdio;
import std.conv;
import std.string;
import std.algorithm;
//import std.algorithm.mutation;
import std.array;
import std.regex;
import std.range;
import std.container.array;

import rbf.field;
import rbf.fieldcontainer;
import rbf.recordfilter;


/***********************************
 * This record class represents a record as found in record-based files
 */
class Record : FieldContainer!Field {

private:

	string _name;										/// record name
	string _description;						/// record descrption
	bool _keep = true;							/// true is we want to keep this record when
																	/// looping using a reader

public:
	/**
	 * creates a new record object
	 *
	 * Params:
	 *	name = name of the record
	 *  description = a generally long description of the record
	 *
	 * Examples:
	 * --------------
	 * auto record = new Record("FIELD1", "Field1 description");
	 * --------------
	 */
	this(in string name, in string description)
	{
			enforce(name != "", "record name should not be empty!");
			_name        = name;
			_description = description;

			// pre-allocate array of fields
			super();
			//writefln("created %s %s", name, description);
	}

	// set/get properties
	@property string name() { return _name; }
	@property string description() { return _description; }
	@property bool keep() { return _keep; }
	@property void keep(bool keep) { _keep = keep; }

	/**
	 * sets record value from one string
	 *
	 * Params:
	 *	s = string to split according to all fields
	 *
	 * Examples:
	 * --------------
	 * record.value = "AAAAA0001000020DDDDDEEEEEFFFFFGGGGGHHHHHIIIIIJJJJJKKKKKLLLLLMMMMMNNNNN00010"
	 * --------------
	 */
	@property void value(string s)
	{
		// add or strip chars from string if string has not the same length as record
		if (s.length < _length) {
			s = s.leftJustify(_length);
		}
		else if (s.length > _length) {
			s = s[0.._length];
		}

		// assign each field to a slice of s
		this.each!(f => f.value = s[f.lowerBound..f.upperBound]);
	}

	/**
	 * value of a record is the concatenation of all field raw values
	 */
	@property string value()
	{
		return fieldRawValues.join("");
	}

	/**
	 * return the list of all field names contained in the record
	 */
	@property string[] fieldNames()
	{
		mixin(FieldContainer!Field.getMembersData("name"));
	}

	/**
	 * return the list of all field values contained in the record
	 */
	@property string[] fieldValues()
	{
		mixin(FieldContainer!Field.getMembersData("value"));
	}

	/**
	 * return the list of all field raw values contained in the record
	 */
	@property string[] fieldRawValues()
	{
		mixin(FieldContainer!Field.getMembersData("rawValue"));
	}


	/**
	 * add a new Field object.
	 *
	 * Params:
	 *	field = field object to be added
	 * Examples:
	 * --------------
	 * auto record = new Record("FIELD1", "Field1 description");
	 * record ~ new Field("FIELD1", "Field1 description", "I", 10);
	 * --------------
	 *
	 */
	void opOpAssign(string op)(Field field) if (op == "~")
	{
		// set index & offset
		field.index  = this.size;
		field.offset = this.length;

		// add element
		super.opOpAssign!"~"(field);

		// lower/upper bounds calculation inside the record
		field.lowerBound = field.offset;
		field.upperBound = field.offset + field.length;
	}


	/**
	 * print out Record properties with all field and record data
	 */
	override string toString()
	{
		auto s = "\nname=<%s>, description=<%s>, length=<%u>, keep=<%s>\n".format(name, description, length, keep);
		foreach (field; this)
		{
			s ~= field.toString();
			s ~= "\n";
		}
		return(s );
	}

	/**
	 * return a string of the XML representation of Record
	 */
	string toXML() {
		auto xml = `<record name="%s" description=""%s">`.format(name, description);
		xml ~= join(array(this[].map!(e => "\t" ~ e.toXML)), "\n");
		xml ~= "</record>";

		return xml;
	}


	/**
	 * match a record against a set of boolean conditions to filter data
	 * returns True is all conditions are met
	 */
	bool matchRecordFilter(RecordFilter filter)
	{
		//writefln("=======> %s",filter);
		// now for each filter, just check it out
		foreach (RecordClause c; filter)
		{
			// field name not found: just return false
			if (c.fieldName !in this) {
				return false;
			}

			// loop on all fields for this requested field
			bool condition = false;

			//writefln("number of fields %s is %d",c.fieldName, this[c.fieldName].length);
			foreach (Field field; this[c.fieldName]) {
				// if one condition is false, then get out
				//writefln("looking at field %s:%s", name, field.name);
				condition |= field.isFieldFilterMatched(c.operator, c.scalar);
			}

			if (!condition) return false;
		}

		// if we didn't return, condition is true
		return true;
	}

}


import std.exception;
unittest {
	writefln("-------------------------------------------------------------");
	writeln(__FILE__);
	writefln("-------------------------------------------------------------");

	// check wrong arguments
	assertThrown(new Record("", "Rec description"));

	// main test
	auto rec = new Record("RECORD_A", "This is my main and top record");
	writeln("avant");
	rec ~= new Field("FIELD1", "Desc1", "A/N", 10);
	writeln("apres");
	rec ~= new Field("FIELD2", "Desc2", "A/N", 10);
	rec ~= new Field("FIELD3", "Desc3", "A/N", 10);
	rec ~= new Field("FIELD2", "Desc2", "A/N", 10);
	rec ~= new Field("FIELD2", "Desc2", "A/N", 10);

	// test properties
	assert(rec.name == "RECORD_A");
	assert(rec.description == "This is my main and top record");
	assert(rec.length == 50);
	assert(rec.size == 5);
	assert(rec.keep == true);

	// test in
	assert("NON_PRESENT" !in rec);
	assert("FIELD1" in rec);

	// set value
	auto s = "AAAAAAAAAABBBBBBBBBBCCCCCCCCCCDDDDDDDDDDEEEEEEEEEE";
	rec.value = s;
	assert(rec.value == s);

	// test fields
	assert(rec[0].name == "FIELD1");
	assert(rec[0].description == "Desc1");
	assert(rec[0].length == 10);
	//assert(rec[0].type == AtomicType.ALPHANUMERICAL);





	writeln(rec);


	rec.keepOnly(["FIELD3","FIELD2"]);
	writeln(rec);

	//core.stdc.stdlib.exit(0);


	writeln(rec.fieldNames);
	writeln(rec.fieldValues);


}
