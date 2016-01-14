// D import file generated from 'source/rbf/fieldtype.d'
module rbf.fieldtype;
pragma (msg, "========> Compiling module ", "rbf.fieldtype");
import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.exception;
import std.range;
import rbf.errormsg;
import rbf.log;
import rbf.field : TVALUE;
static TVALUE overpunch(TVALUE s);
alias CmpFunc = bool delegate(const TVALUE, const string, const TVALUE);
alias FmtFunc = string delegate(const char[] value, const size_t length);
alias Conv = TVALUE function(TVALUE);
enum AtomicType 
{
	decimal,
	integer,
	date,
	string,
}
struct FieldTypeMeta
{
	string name;
	AtomicType type;
	string stringType;
	string pattern;
	string format;
	Conv preConv;
	CmpFunc filterTestCallback;
	FmtFunc formatterCallback;
}
class FieldType
{
	public 
	{
		FieldTypeMeta meta;
		this(string nickName, string declaredType);
		@property bool isNumeric();
		bool isFieldFilterMatched(TVALUE lvalue, string op, TVALUE rvalue);
		static string testFilter(T)(string op)
		{
			return "condition = (to!T(lvalue)" ~ op ~ "to!T(rvalue));";
		}
		bool matchFilter(T)(in TVALUE lvalue, in string operator, in TVALUE rvalue)
		{
			bool condition;
			try
			{
				switch (operator)
				{
					case "=":
					{
					}
					case "==":
					{
						mixin(testFilter!T("=="));
						break;
					}
					case "!=":
					{
						mixin(testFilter!T("!="));
						break;
					}
					case "<":
					{
						mixin(testFilter!T("<"));
						break;
					}
					case ">":
					{
						mixin(testFilter!T(">"));
						break;
						static if (is(T == string))
						{
							case "~":
							{
								condition = !matchAll(lvalue, regex(rvalue)).empty;
								break;
							}
							case "!~":
							{
								condition = matchAll(lvalue, regex(rvalue)).empty;
								break;
							}
						}

					}
					default:
					{
						throw new Exception(MSG030.format(operator));
					}
				}
			}
			catch(ConvException e)
			{
				log.log(LogLevel.WARNING, lvalue, operator, rvalue, T.stringof);
			}
			return condition;
		}
		string formatter(T)(in char[] value, in size_t length)
		{
			if (value == "")
				return to!string(' '.repeat(length));
			T convertedValue = value != "" ? to!T(value) : T.init;
			return meta.format.format(length, length, convertedValue);
		}
	}
}
