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

enum RootType { STRING, NUMERIC }

// filter matching method pointer
alias MATCH_FILTER = bool delegate(string,string,string);

/***********************************
 *This field class represents a field as found
 * in record-based files
 */
class FieldType {
private:

	string _declaredType;								/// the field type as read from the layout file
	AtomicType _atom;										/// the corresponding "real" type
	RootType _root;											/// main type
	Regex!char _re;				  						/// the pattern the field should stick to
	MATCH_FILTER _filterTestCallback;  	/// method to test whether a value matches a filter

public:
	/**
 	 * creates a new type for a field object
	 *
	 * Params:
	 *  type = whether the field holds numerical, alphanumerical... data
	 *
	 * Examples:
  	 * -----------------------------------------------------------------------
 	 * auto ft = new FieldType('A/N');
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
				_root = RootType.NUMERIC;
				_filterTestCallback = &matchFilter!float;
				break;
			case "I":
				_atom = AtomicType.INTEGER;
				_root = RootType.NUMERIC;
				_filterTestCallback = &matchFilter!long;
				break;
			case "D":
				_atom = AtomicType.DATE;
				_root = RootType.STRING;
				_filterTestCallback = &matchFilter!string;
				break;
			case "A":
				_atom = AtomicType.ALPHABETICAL;
				_root = RootType.STRING;
				_filterTestCallback = &matchFilter!string;
				break;
			case "AN":
			case "A/N":
				_atom = AtomicType.ALPHANUMERICAL;
				_root = RootType.STRING;
				_filterTestCallback = &matchFilter!string;
				break;
			default:
				throw new Exception("unknown field type %s".format(type));
		}
	}

	// properties
	@property AtomicType type() { return _atom; }
	@property RootType rootType() { return _root; }
	@property void pattern(string p) { _re = regex(p); }

	// toString
	override string toString()
	{
		return format("type=%s, rootType=%s, pattern=%s", _atom, _root, _re);
	}

	// test a filter
	bool testFieldFilter(string lvalue, string op, string rvalue) {
		return _filterTestCallback(lvalue, op, rvalue);
	}

	// templated tester for testing a value against a filter and an operator
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
	assertThrown(new FieldType("B"));

	// create new field and check methods
	auto ft = new FieldType("AN");

	assert(ft.type == AtomicType.ALPHANUMERICAL);
	writeln(ft);

}
