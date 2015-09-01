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
import std.array;
import std.regex;
import std.range;

import rbf.field;

/***********************************
 * This record class represents a record as found in record-based files
 */
class Record {

private:

	immutable string _name;			/// record name
	immutable string _description;	/// record descrption

	Field[] _field_list;	/// dynamic array used to store elements
	Field[][string] _field_map; /// hash map to store fields (key is field name)

	ulong _length;           /// length of record = sum of field lengths

	string _line;			/// save string from file

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
			_name = name;
			_description = description;
	}

	@property string name() { return _name; }
	@property string description() { return _description; }

	@property string line() { return _line; }
	@property void line(string new_line) { _line = new_line; }

	@property ulong length() { return _length; }


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
		// s length should equal record length
		//enforce(length == s.length, "line (%s) length = %d is over record length (%d)".format(s, s.length, length));
		// add or strip chars from string if string has not the same length as record
		if (s.length < _length) {
			s = s.leftJustify(_length);
		}
		else if (s.length > _length) {
			s = s[0.._length];
		}

		// loop for each element and set each value
		ushort offset = 0;
		foreach (f; _field_list) {
			f.value = s[offset..offset+f.length];
			offset += f.length;
		}
	}

	/**
	 * value of a record is the concatenation of all field values
	 */
	@property string value()
	{
		return reduce!((a, b) => a ~ b.rawvalue)("", _field_list);
	}

	/**
	 * return the list of all field names
	 */
	@property string[] fieldNames()
	{
		 return array(map!(f => f.name)(_field_list));
	}

	/**
	 * return the list of all field values
	 */
	@property string[] fieldValues()
	{
		 return array(map!(f => f.value)(_field_list));
	}

	/**
	 * fields having the same name can be part of the same record. This method is
	 * aimed at renaming automagically fields by adding a counter to each duplicate
	 * The record is duplicated and not modified inline
	 */
	 void autoRename()
	 {
		foreach (fieldName; _field_map.byKey) {
			// more than one instance?
			if (_field_map[fieldName].length > 1) {

				// rename each field
				auto i = 1;
				foreach (ref field; _field_map[fieldName]) {
					// build new field name
					field.name = field.name ~ to!string(i++);

					// rebuld map
					_field_map[field.name] ~= field;
				}

				// but now no more older field name!
				_field_map.remove(fieldName);
			}
		}
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
		field.index = _field_list.length;
		field.offset = this.length;

		// store a new element in array
		_field_list ~= field;

		// store in map (used for auto-renaming)
		_field_map[field.name] ~= field;

		// we add a new field, so increment length
		_length += field.length;
	}

	/**
	 * [] operator to retrieve i-th field object
	 *
	 * Params:
	 *	i = index of the i-th field object to retrieve
	 *
	 * Examples:
	 * --------------
	 * auto f = record[0]  // returns the first field object
	 * --------------
	 */
	Field opIndex(size_t i)
	{
		// i should fit within consistent bounds
		enforce(0 <= i && i < _field_list.length, "index %d is out of bounds for _field_list[]".format(i));
		return(_field_list[i]);
	}

	/**
	 * [] operator to retrieve field object whose name is passed as an argument
	 *
	 * Params:
	 *	fieldName = name of the field to retrieve
	 *
	 * Examples:
	 * --------------
	 * auto f = record["FIELD1"]  // returns the field objects named FIELD1
	 * --------------
	 */
	Field[] opIndex(string fieldName)
	{
		// check if fieldName is in the record
		enforce(fieldName in this, "field %s is not found in record %s".format(fieldName, name));

		return _field_map[fieldName];
	}

	/**
	 * in operator: test if field whose name is passed as argument is found in record
	 *
	 * Params:
	 *	fieldName = name of the field to retrieve
	 *
	 * Examples:
	 * --------------
	 * if ("FIELD1" in record) ...      // test if FIELD1 is in record
	 * --------------
	 */
	Field[]* opBinaryRight(string op)(string fieldName)
	{
		if (op == "in") {
		    return (fieldName in _field_map);
		}
	}


	/**
	 * to loop with foreach loop on all fields
	 *
	 * Examples:
	 * --------------
	 * foreach (Field f; record)
	 	{ writeln(f); }
	 * --------------
	 */
	int opApply(int delegate(ref Field) dg)
	{
		int result = 0;

		for (int i = 0; i < _field_list.length; i++)
		{
		    result = dg(_field_list[i]);
		    if (result)
			break;
		}
		return result;
	}

	/**
	 * duplicate a record with all its fields and values
	 */
	Record dup()
	{
		Record copied = new Record(name, description);
		foreach (field; _field_list) {
			copied ~= field.dup();
		}
		return copied;
	}

	Record fromList(string[] listOfFields) {
		Record copied = new Record(name, description);
		foreach (field; _field_list) {
			if (listOfFields.canFind(field.name)) {
				copied ~= field.dup();
			}
		}
		return copied;
	}

	/**
	 * get the i-th field whose is passed as argument in case of duplicate
	 * field names (starting from 0)
	 * Examples:
	 * --------------
	 * rec.get("FIELD",5) // return the field object of the 6-th field named FIELD
	 * rec.get("FIELD") // return the first field object named FIELD
	 * --------------
	 */
	Field get(string fieldName, ushort index = 0) {
		enforce(fieldName in this, "field %s is not found in record %s".format(fieldName, name));
		enforce(0 <= index && index < _field_map[fieldName].length, "field %s, index %d is out of bounds".format(fieldName,index));

		return _field_map[fieldName][index];
	}

	/**
	 * just print out a record with field names and field values
	 */
	string toTxt()
	{
		// length of the record when printed out
		ulong length;
		string[] fields, values;

		// wisely build our ascii table
		foreach (Field f; this) {
			length = max(f.length, f.name.length);

			fields  ~= f.name.leftJustify(length);
			values  ~= f.value.leftJustify(length);
		}

		// write out table
		return ("%s\n%s\n".format(join(fields,"|"), join(values,"|")));
	}

	/**
	 * to match an attribute more easily
	 *
	 * Examples:
	 * --------------
	 * rec.FIELD1(5) returns the value of the 6-th field named FIELD1
	 * --------------
	 */
	string opDispatch(string fieldName)(ushort index)
	{
		enforce(0 <= index && index < _field_map[fieldName].length, "field %s, index %d is out of bounds".format(fieldName,index));
		return this[fieldName][index].value;
	}

	/**
	 * to match an attribute more easily
	 *
	 * Examples:
	 * --------------
	 * rec.FIELD1 returns the value of the field named FIELD1 in the record
	 * --------------
	 */
	@property string opDispatch(string attrName)()
	{
		//writefln("attr=%s", this[name][0].value);
		return this[attrName][0].value;
	}

	/**
	 * print out Record properties with all field and record data
	 */
	override string toString()
	{
		auto s = "\nname=<%s>, description=<%s>, length=<%u>\n".format(name, description, length);
		foreach (f; _field_list)
		{
			s ~= f.toString();
			s ~= "\n";
		}
		return(s);
	}

	/**
	 * match a record against a set of boolean conditions to filter data
	 */
	bool matchCondition(string[] filter)
	{
		// useful structure mapping a condition
		struct condition {
			string fieldName;
			string operator;
			string scalar;
		}

		// this is the regex to use to split the condition
		static auto reg = regex(r"(\w+)(\s*)(=|!=|>|<|~|!~)(\s*)(.+)$");

		// and the array holding conditions
		condition[] fullCondition;

		// read each condition to extract field name, operator and value
		foreach (string s; filter)
		{
			auto m = match(s, reg);
			fullCondition ~= condition(
						m.captures[1].strip(),
						m.captures[3].strip(),
						m.captures[5].strip()
			);
		}
		//writeln(fullCondition);


		// now for each condition, try it
		foreach (condition c; fullCondition)
		{
			// field name not found: just return false
			if (c.fieldName !in this) return false;

			// get field value
			Field f = this[c.fieldName][0];
			//writefln("<%s> <%s> cond=<%s>", f.name, f.value, f.matchCondition(c.operator, c.scalar));

			// if one condition is false, then get out
			if (!f.matchCondition(c.operator, c.scalar)) return false;

			// otherwise, get field value and compare it to scalar values
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
	//auto rec = Record.read_from_file("records.txt");
	auto rec = new Record("RECORD_A", "This is my main and top record");

	rec ~= new Field("FIELD1", "Desc1", "A/N", 10);
	rec ~= new Field("FIELD2", "Desc2", "A/N", 10);
	rec ~= new Field("FIELD3", "Desc3", "A/N", 10);
	rec ~= new Field("FIELD2", "Desc2", "A/N", 10);
	rec ~= new Field("FIELD2", "Desc2", "A/N", 10);

	// test members
	assert(rec.name == "RECORD_A");
	assert(rec.description == "This is my main and top record");
	assert(rec.length == 50);

	// test in
	assert("NON_PRESENT" !in rec);
	assert("FIELD1" in rec);

	// set value
	auto s = "AAAAAAAAAABBBBBBBBBBCCCCCCCCCCDDDDDDDDDDEEEEEEEEEE";
	rec.value = s;
	writeln(rec);

	// get value
	assert(rec.value == s);

	// dup
	auto copy = rec.dup();
	assert(copy.value == s);

	// index
	assert(rec[0].name == "FIELD1");
	assert(rec["FIELD1"][0].value == "AAAAAAAAAA");

	writeln("Fields");

	foreach (Field f; rec) {
		writeln(f);
	}

	writeln(rec.fieldNames);
	writeln(rec.fieldValues);


	auto rec_renamed = rec.dup;
	rec_renamed.autoRename();

	writeln(rec_renamed.fieldNames);
	writeln(rec_renamed);

	//writeln(rec.matchCondition(["FIELD_A1 == AAAAA", "FIELD_A2=10"]));
	//writeln("toto");
	//writeln("FIELD_B1" in rec);
	assert("FIELD21" in rec_renamed);

	//writeln(rec_renamed.toTxt());
	struct S {
		string _a;
		this(string a) { _a = a; }
		@property string opDispatch(string attr)() {
			enum s = attr;
			return "toto";
		}
	}

	auto s1 = new S("aaa");
	writefln("passed values=%s, %s, %s",
		rec.FIELD1, rec_renamed.FIELD21, rec.FIELD2(2));


}
