module rbf.fieldtype;
pragma(msg, "========> Compiling module ", __MODULE__);

/*

Implements the methods used in the <fieldtype> definition tag:

	<fieldtype name="CHAR" type="string" pattern="\w+" format="" />

	Here we need type, pattern, format,

*/

import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.exception;

static string overpunch(string s) {
	static string posTable = makeTrans("{ABCDEFGHI}", "01234567890");
	static string negTable = makeTrans("JKLMNOPQR", "123456789");

	string trans;

	// found {ABCDEFGHI} in s: need to translate
	if (s.indexOfAny("{ABCDEFGHI}") != -1) {
		trans = translate(s, posTable);
	}
	else if (s.indexOfAny("JKLMNOPQR") != -1) {
		trans = "-" ~ translate(s, negTable);
	}
	return trans;
}


// filter matching method pointer
alias CmpFunc = bool delegate(string,string,string);
alias Conv = string function(string);

/***********************************
 * all possible field types for a field
* in a record-based file
 */
enum AtomicType {
	decimal,
	integer,
	date,
	string,
	overpunchedInteger
}

/***********************************
 * This field type class represents possible field types
 */
class FieldType {
private:

	AtomicType _type;								/// the corresponding "real" type
	CmpFunc _filterTestCallback;  	/// method to test whether a value matches a filter
	string  _pattern;						    /// standard pattern as the field
	string _stringType;							/// as passed to constructor
	string _name;										/// declared type name

public:

	Conv preConv;										/// conversion occruing before setting a field value

	/**
 	 * creates a new type from a string type
	 *
	 * Params:
	 *  type = whether the field holds numerical, alphanumerical... data
	 */
	this(string name, string type, string pattern = "", string format = "")
	{
		// set type according to what is passed
		_stringType = type;
		_type       = to!AtomicType(type);
		_pattern    = pattern;
		_name				= name;

		final switch (_type)
		{
			case AtomicType.decimal:
				_filterTestCallback = &matchFilter!float;
				break;
			case AtomicType.integer:
				_filterTestCallback = &matchFilter!long;
				break;
			case AtomicType.overpunchedInteger:
				_filterTestCallback = &matchFilter!long;
				preConv             = &overpunch;
				break;
			case AtomicType.date:
				_filterTestCallback = &matchFilter!string;
				break;
			case AtomicType.string:
				_filterTestCallback = &matchFilter!string;
				break;
		}
	}

	/// return atomic type
	@property AtomicType fieldType() { return _type; }
	///
	unittest {
		auto ft = new FieldType("N","decimal");
		assert(ft.fieldType == AtomicType.decimal);
	}

	/// type pattern
	@property string pattern() { return _pattern; }
	@property void pattern(string p) { _pattern = p; }
	@property string stringType() { return _stringType; }
	@property string name() { return _name; }

	/// toString
	// override string toString()
	// {
	// 	return format("type=%s, pattern=%s", _type, _pattern);
	// }

	/// test a filter
	bool isFieldFilterMatched(string lvalue, string op, string rvalue) {
		return _filterTestCallback(lvalue, op, rvalue);
	}
	///
	unittest {
		auto ft = new FieldType("D","decimal");
		assert(ft.isFieldFilterMatched("50", ">", "40"));
		assert(ft.isFieldFilterMatched("40", "==", "40"));
		assertThrown(ft.isFieldFilterMatched("40", "~", "40"));

		ft = new FieldType("STRING","string");
		assert(ft.isFieldFilterMatched("AABBBBB", "~", "^AA"));
		assert(ft.isFieldFilterMatched("AABBBBB", "!~", "^BA"));
	}

	// templated tester for testing a value against a filter and an operator
	static string testFilter(T)(string op) {
		/*
		static if (is(T == string))
			return "condition = (lvalue" ~ op ~ "rvalue);";
		else*/
			return "condition = (to!T(lvalue)" ~ op ~ "to!T(rvalue));";
	}
	bool matchFilter(T)(string lvalue, string operator, string rvalue) {
		bool condition;

		switch (operator) {
			case "=":
			case "==":
				mixin(testFilter!T("=="));
				break;
			case "!=":
				mixin(testFilter!T("!="));
				break;
			case "<":
				mixin(testFilter!T("<"));
				break;
			case ">":
				mixin(testFilter!T(">"));
				break;
			static if (is(T == string)) {
				case "~":
					condition = !match(lvalue, regex(rvalue)).empty;
					break;
				case "!~":
					condition = match(lvalue, regex(rvalue)).empty;
					break;
			}
			default:
				throw new Exception("error: operator %s not supported".format(operator));
		}
		return condition;
	}

}
///
unittest {

	FieldType[string] map;

	map["I"]   = new FieldType("I","decimal", r"\d+");
	map["A/N"] = new FieldType("A/N","string", r"\w+");

	map["N"]   = new FieldType("N","overpunchedInteger", r"[\dA-R{}]+");
	assert(map["N"].preConv("6{}") == "600");
	assert(map["N"].preConv("6J1") == "-611");

}
