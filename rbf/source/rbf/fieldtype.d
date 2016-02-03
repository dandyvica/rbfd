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
import std.range;

import rbf.errormsg;
import rbf.log;
import rbf.field: TVALUE;


// this converter method is necessary because of the overpunch legacy way
// of conveying ascii data in some IATA formats like HOT
// it just converts some ASCII chars to others
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
alias FmtFunc = string delegate(const char[] value, const size_t length);
alias Conv = TVALUE function(TVALUE);

/***********************************
 * all possible field types for a field in a record-based file
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
	string name;                    /// name of the field type to refer to
	AtomicType type;                /// field type converted to enum type
	string stringType;              /// field type as read in the XML layout file
	string pattern;                 /// field pattern as a regex to fit to
	string format;                  /// when converted back to a string value, printf()-like format string
	Conv preConv;				    /// conversion method called before setting a field value
	CmpFunc filterTestCallback; 	/// method to test whether a value matches a filter
    FmtFunc formatterCallback;      /// function used to convert a value
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
	 *  nickname = name to which the <fieldtype> tag refers (it's name attribute)
     *  deckaredType = name of the real field type and is matched to enum
	 */
	this(string nickName, string declaredType)
	{
		// set type according to what is passed as arguments
		with(meta) 
        {
			stringType = declaredType;
			type       = to!AtomicType(stringType);
			name	   = nickName;

            // set features of this type according to its basic type
			final switch (type)
			{
				case AtomicType.decimal:
					filterTestCallback = &matchFilter!double;
                    formatterCallback  = &formatter!double;

                    // default pattern and format string for this type
                    meta.pattern = `[\d.]+`;
                    meta.format  = "%0*.*g";
					break;
				case AtomicType.integer:
					filterTestCallback = &matchFilter!ulong;
                    formatterCallback  = &formatter!ulong;

                    // default pattern and format string for this type
                    meta.pattern = `\d+`;
                    meta.format  = "%0*.*d";
					break;
				case AtomicType.date:
					filterTestCallback = &matchFilter!string;
                    formatterCallback  = &formatter!string;

                    // default pattern and format string for this type
                    meta.pattern = `\d+`;
                    meta.format  = "%-*.*s";
					break;
				case AtomicType.string:
					filterTestCallback = &matchFilter!string;
                    formatterCallback  = &formatter!string;

                    // default pattern and format string for this type
                    meta.pattern = `[\w/\*\.,\-]+`;
                    meta.format  = "%-*.*s";
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

	/// Test a record filter. Basically it tests whether a lvalue is matching an rvalue
	bool isFieldFilterMatched(TVALUE lvalue, string op, TVALUE rvalue) 
    {
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

		try 
        {
            // operator is normally limited to those listed below
			switch (operator) 
            {
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
                // and some operators only make sense if the field type is string
				static if (is(T == string)) 
                {
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

    // format a field according to its root type
	string formatter(T)(in char[] value, in size_t length) 
    {
        // no value? Just return blank string
        if (value == "") return to!string(' '.repeat(length));

        // we need to check whether value is empty. In that case, we just send back the T type default value
        T convertedValue = (value != "") ? to!T(value) : T.init;

        // float type processing is kind of specific
        /*
		static if (is(T == float)) 
        {
            // precision is used to reformat
            size_t precision;
            size_t decPoint;

            // this is a true float value. Due to formatting issue with floats, new to get exact
            // number of digits after the decimal point
            decPoint = value.indexOf('.');

            // decimal point found!
            if (decPoint != -1)
            {
                precision = value.length - decPoint;
            }
            return meta.format.format(length, precision, value);
        }
        else
        {
            return meta.format.format(length, length, convertedValue);
        }
        */
       return meta.format.format(length, length, convertedValue);
            
    }

}
///
unittest {

	FieldType[string] map;

	map["I"]   = new FieldType("I","decimal");
	map["I"].meta.pattern = r"\d+";
	map["A/N"] = new FieldType("A/N","string");
	map["A/N"].meta.pattern = r"\w+";

}
