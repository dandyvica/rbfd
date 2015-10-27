// D import file generated from 'source/rbf/fieldtype.d'
module rbf.fieldtype;
pragma (msg, "========> Compiling module ", "rbf.fieldtype");
import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.exception;
static string overpunch(string s);
alias CmpFunc = bool delegate(string, string, string);
alias Conv = string function(string);
enum AtomicType 
{
	decimal,
	integer,
	date,
	string,
	overpunchedInteger,
}
struct ExtraFieldTypeInfo
{
	string pattern;
	string format;
	bool checkPattern;
}
class FieldType
{
	private 
	{
		AtomicType _type;
		CmpFunc _filterTestCallback;
		string _pattern;
		string _stringType;
		string _name;
		public 
		{
			Conv preConv;
			ExtraFieldTypeInfo extra;
			this(string name, string type);
			@property AtomicType fieldType();
			@property string stringType();
			@property string name();
			override string toString();
			bool isFieldFilterMatched(string lvalue, string op, string rvalue);
			static string testFilter(T)(string op)
			{
				return "condition = (to!T(lvalue)" ~ op ~ "to!T(rvalue));";
			}
			bool matchFilter(T)(string lvalue, string operator, string rvalue)
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
							throw new Exception("error: operator %s not supported".format(operator));
						}
					}
				}
				catch(ConvException e)
				{
					stderr.writeln("error: converting value %s %s %s to type %s".format(lvalue, operator, rvalue, T.stringof));
				}
				return condition;
			}
		}
	}
}
