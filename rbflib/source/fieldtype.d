module rbf.fieldtype;

import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;

/***********************************
 * all possible field types for a field
* in a record-based file
 */
enum AtomicType {
	FLOAT,
	INTEGER,
	DATE,
	ALPHABETICAL,
	ALPHANUMERICAL
}

alias TESTER = bool delegate(string,string,string);

/***********************************
 *This field class represents a field as found
 * in record-based files
 */
class FieldType {
private:

	string _declaredType;
	AtomicType _atom;

	Regex!char re;

	TESTER tester;

public:
	/**
 	 * creates a new field object
	 *
	 * Params:
	 * 	name = name of the field
	 *  description = a generally long description of the field
	 *  length = length in bytes of the field. Should be >0
	 *  type = whether the field holds numerical, alphanumerical... data
	 *
	 * Examples:
  	 * -----------------------------------------------------------------------
 	 * auto ft = new FieldType('FIELD1', 'Field description', 'A/N', 15);
  	 * -----------------------------------------------------------------------
	 */
	this(in string type)
	// verify pre-conditions
	{
		// set type according to what is passed
		_declaredType = type;

		switch (type)
		{
			case "N":
				_atom = AtomicType.FLOAT;
				tester = &matchFilter!float;
				break;
			case "I":
				_atom = AtomicType.INTEGER;
				break;
			case "D":
				_atom = AtomicType.DATE;
				break;
			case "A":
				_atom = AtomicType.ALPHABETICAL;
				break;
			case "AN":
			case "A/N":
				_atom = AtomicType.ALPHANUMERICAL;
				break;
			default:
				throw new Exception("unknown field type %s".format(type));
		}
	}

	@property AtomicType type() { return _atom; }

	@property void pattern(string p) { re = regex(p); }

	static string testFilter(T)(string op) {
		static if (is(T t == string))
			return "condition = (lvalue" ~ op ~ "rvalue);";
		else
			return "condition = (to!T(lvalue)" ~ op ~ "to!T(rvalue));";
	}

	bool matchFilter(T)(string lvalue, string operator, string rvalue) {
		bool condition;

		switch (operator) {
			case "=":
			case "==":
				mixin(testFilter!T("=="));
				break;
			case "<":
				mixin(testFilter!T("<"));
				break;
			default:
				throw new Exception("operator %s not supported".format(operator));
		}

		return condition;
	}

}



import std.exception;
unittest {
	writefln("-------------------------------------------------------------");
	writeln(__FILE__);
	writefln("-------------------------------------------------------------");

	// check wrong arguments
	assertThrown(new Field("","Ticket/Document Number","A", 5));
	assertThrown(new Field("TDNR","Ticket/Document Number","B", 5));
	assertThrown(new Field("TDNR","Ticket/Document Number","A", 0));

	// create new field and check methods
	auto f = new Field("FIELD1","First field","AN",5);

	assert(f.name == "FIELD1");
	assert(f.description == "First field");
	assert(f.length == 5);
	assert(f.type == FieldType.ALPHANUMERICAL);

	// test methods
	f.value = "12345";
	assert(f.value == "12345");

	writeln(f);

	writeln(f.dup());

}
