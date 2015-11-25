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

import rbf.errormsg;
import rbf.field: TVALUE;

static TVALUE overpunch(TVALUE s) 
{
	static string posTable = makeTrans("{ABCDEFGHI}", "01234567890");
	static string negTable = makeTrans("JKLMNOPQR", "123456789");

	auto trans = s;

	// found {ABCDEFGHI} in s: need to translate
	if (s.indexOfAny("{ABCDEFGHI}") != -1) 
    {
		trans = translate(s, posTable);
	}
	else if (s.indexOfAny("JKLMNOPQR") != -1) 
    {
		trans = "-" ~ translate(s, negTable);
	}
	return trans;
}


// filter matching method pointer
alias CmpFunc = bool delegate(const TVALUE,const string,const TVALUE);
alias Conv = TVALUE function(TVALUE);

/***********************************
 * all possible field types for a field
* in a record-based file
 */
enum AtomicType {
	decimal,
	integer,
	date,
	string
}

/***********************************
 * extra information for a field type
* in a record-based file
 */
struct FieldTypeMeta {
	string name;
	AtomicType type;
	string stringType;
	string pattern;
	string format;
	//bool checkPattern;
	string fmtPattern;
	Conv preConv;								 /// conversion occruing before setting a field value
	CmpFunc filterTestCallback; 	/// method to test whether a value matches a filter
}


/***********************************
 * This field type class represents possible field types
 */
class FieldType {

public:

	FieldTypeMeta meta;

	/**
 	 * creates a new type from a string type
	 *
	 * Params:
	 *  type = whether the field holds numerical, alphanumerical... data
	 */
	this(string nickName, string declaredType)
	{
		// set type according to what is passed
		with(meta) {
			stringType = declaredType;
			type       = to!AtomicType(stringType);
			name	   = nickName;

			final switch (type)
			{
				case AtomicType.decimal:
					filterTestCallback = &matchFilter!float;
					fmtPattern = "%f";
					break;
				case AtomicType.integer:
					filterTestCallback = &matchFilter!long;
					fmtPattern = "%d";
					break;
				case AtomicType.date:
					filterTestCallback = &matchFilter!string;
					fmtPattern = "%s";
					break;
				case AtomicType.string:
					filterTestCallback = &matchFilter!string;
					fmtPattern = "%s";
					break;
			}
		}
	}

	// numeric fields might lead to different types in SQL or Excel. So
    // we need such a method to test if a field type is numeric
	@property bool isNumeric() 
    {
		return meta.type == AtomicType.decimal || meta.type == AtomicType.integer;
	}

	/// test a record filter. Basically it tests whether a value is matching
    /// a result
	bool isFieldFilterMatched(TVALUE lvalue, string op, TVALUE rvalue) {
		return meta.filterTestCallback(lvalue, op, rvalue);
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
	static string testFilter(T)(string op) 
    {
		return "condition = (to!T(lvalue)" ~ op ~ "to!T(rvalue));";
	}
	bool matchFilter(T)(in TVALUE lvalue, in string operator, in TVALUE rvalue) 
    {
		bool condition;

		try {
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
						condition = !matchAll(lvalue, regex(rvalue)).empty;
						break;
					case "!~":
						condition = matchAll(lvalue, regex(rvalue)).empty;
                        //writefln("<%s> %s <%s> = %s", lvalue, operator, rvalue, condition);
						break;
				}
				default:
					throw new Exception(MSG030.format(operator));
			}
		}
		catch (ConvException e) 
        {
            log.log(LogLevel.WARNING, lvalue, operator, rvalue, T.stringof); 
			//stderr.writeln("error: converting value %s %s %s to type %s".format(lvalue, operator, rvalue, T.stringof));
		}

		return condition;
	}

}
///
unittest {

	FieldType[string] map;

	map["I"]   = new FieldType("I","decimal");
	map["I"].meta.pattern = r"\d+";
	map["A/N"] = new FieldType("A/N","string");
	map["A/N"].meta.pattern = r"\w+";

	// map["N"]   = new FieldType("N","overpunchedInteger");
	// map["N"].meta.pattern = r"[\dA-R{}]+";
	// assert(map["N"].meta.preConv("6{}") == "600");
	// assert(map["N"].meta.preConv("6J1") == "-611");

}
