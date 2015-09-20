// D import file generated from 'source/rbf/fieldtype.d'
module rbf.fieldtype;
import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
enum AtomicType 
{
	FLOAT,
	INTEGER,
	DATE,
	ALPHABETICAL,
	ALPHANUMERICAL,
}
enum RootType 
{
	STRING,
	NUMERIC,
}
alias MATCH_FILTER = bool delegate(string, string, string);
class FieldType
{
	private 
	{
		string _declaredType;
		AtomicType _atom;
		RootType _root;
		Regex!char _re;
		MATCH_FILTER _filterTestCallback;
		public 
		{
			this(in string type);
			@property AtomicType type();
			@property RootType rootType();
			@property void pattern(string p);
			override string toString();
			bool testFieldFilter(string lvalue, string op, string rvalue);
			static string testFilter(T)(string op)
			{
				static if (is(T t == string))
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
					case "<":
					{
						mixin(testFilter!T("<"));
						break;
					}
					default:
					{
						throw new Exception("operator %s not supported".format(operator));
					}
				}
				return condition;
			}
		}
	}
}
import std.exception;
