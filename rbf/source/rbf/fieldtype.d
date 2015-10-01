module rbf.fieldtype;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.exception;

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

/***********************************
 * types boil down to only 2 basic types
 */
enum BaseType { STRING, NUMERIC }

// filter matching method pointer
alias MATCH_FILTER = bool delegate(string,string,string);

/***********************************
 * This field type class represents possible field types
 */
class FieldType {
private:

	string _name;
	BaseType _baseType;								    /// the field type as read from the layout file
	AtomicType _type;										/// the corresponding "real" type
	//BaseType _root;											/// main type
	Regex!char _re;				  						/// the pattern the field should stick to
	MATCH_FILTER _filterTestCallback;  	/// method to test whether a value matches a filter

public:
	/**
 	 * creates a new type from a string type
	 *
	 * Params:
	 *  type = whether the field holds numerical, alphanumerical... data
	 */
	this(string name, string type, string baseType)
	// verify pre-conditions
	{
		// set type according to what is passed
		_name     = name;
		_type     = to!AtomicType(type);
		_baseType = to!BaseType(baseType);

		final switch (_type)
		{
			case AtomicType.FLOAT:
				_filterTestCallback = &matchFilter!float;
				break;
			case AtomicType.INTEGER:
				_filterTestCallback = &matchFilter!long;
				break;
			case AtomicType.DATE:
				_filterTestCallback = &matchFilter!string;
				break;
			case AtomicType.ALPHABETICAL:
				_filterTestCallback = &matchFilter!string;
				break;
			case AtomicType.ALPHANUMERICAL:
				_filterTestCallback = &matchFilter!string;
				break;
		}
	}

	/// return atomic type
	@property AtomicType type() { return _type; }
	///
	unittest {
		auto ft = new FieldType("N", "FLOAT", "NUMERIC");
		assert(ft.type == AtomicType.FLOAT);
	}

	/// return root type which is either only string or numeric
	@property BaseType baseType() { return _baseType; }
	///
	unittest {
		auto ft = new FieldType("N", "FLOAT", "NUMERIC");
		assert(ft.baseType == BaseType.NUMERIC);
	}

	/// set field type regex pattern
	@property void pattern(string p) { _re = regex(p); }

	/// return the string type passed to ctor
	@property string name() { return _name; }

	///
	unittest {
		auto ft = new FieldType("N", "FLOAT", "NUMERIC");
		assert(ft.name == "N");
	}


	/// toString
	override string toString()
	{
		return format("type=%s, baseType=%s, pattern=%s", _type, _baseType, _re);
	}

	/// test a filter
	bool testFieldFilter(string lvalue, string op, string rvalue) {
		return _filterTestCallback(lvalue, op, rvalue);
	}
	///
	unittest {
		auto ft = new FieldType("N", "FLOAT", "NUMERIC");
		assert(ft.testFieldFilter("50", ">", "40"));
	}

	// templated tester for testing a value against a filter and an operator
	static string testFilter(T)(string op) {
		static if (is(T == string))
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
