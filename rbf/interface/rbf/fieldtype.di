// D import file generated from 'source/rbf/fieldtype.d'
module rbf.fieldtype;
pragma (msg, "========> Compiling module ", "rbf.fieldtype");
import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.exception;
enum AtomicType 
{
	decimal,
	integer,
	date,
	string,
}
enum BaseType 
{
	string,
	numeric,
}
alias MATCH_FILTER = bool delegate(string, string, string);
class FieldType
{
	private 
	{
		string _name;
		BaseType _baseType;
		AtomicType _type;
		Regex!char _re;
		MATCH_FILTER _filterTestCallback;
		public 
		{
			this(string name, string type);
			@property AtomicType type();
			@property BaseType baseType();
			@property void pattern(string p);
			@property string name();
			override string toString();
			bool testFieldFilter(string lvalue, string op, string rvalue);
			static string testFilter(T)(string op)
			{
				static if (is(T == string))
				{
					return "condition = (lvalue" ~ op ~ "rvalue);";
				}
				else
				{
					return "condition = (to!T(lvalue)" ~ op ~ "to!T(rvalue));";
				}
			}
			bool matchFilter(T)(string lvalue, string operator, string rvalue)
			{
				bool condition;
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
								condition = !match(lvalue, regex(rvalue)).empty;
								break;
							}
							case "!~":
							{
								condition = match(lvalue, regex(rvalue)).empty;
								break;
							}
						}

					}
					default:
					{
						throw new Exception("error: operator %s not supported".format(operator));
					}
				}
				return condition;
			}
		}
	}
}
