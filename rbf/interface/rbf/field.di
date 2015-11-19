// D import file generated from 'source/rbf/field.d'
module rbf.field;
pragma (msg, "========> Compiling module ", "rbf.field");
import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.typecons;
import std.exception;
import std.typecons;
import std.variant;
import rbf.errormsg;
import rbf.element;
import rbf.fieldtype;
alias TVALUE = string;
pragma (msg, "========> TVALUE = ", TVALUE.stringof);
struct ContextualInfo
{
	ulong index;
	ulong offset;
	ulong occurence;
	ulong lowerBound;
	ulong upperBound;
	typeof(Field.name) alternateName;
}
class Field : Element!(string, ulong, ContextualInfo)
{
	private 
	{
		FieldType _fieldType;
		TVALUE _rawValue;
		TVALUE _strValue;
		byte _valueSign = 1;
		Regex!char _fieldPattern;
		string _charPattern;
		public 
		{
			this(in string name, in string description, FieldType type, in ulong length);
			this(in string csvdata);
			@property FieldType type();
			@property void pattern(in string s);
			bool matchPattern();
			auto @property value()
			{
				return _strValue;
			}
			@property T value(T)()
			{
				return to!T(_strValue) * sign;
			}
			@property void value(TVALUE s);
			auto @property rawValue()
			{
				return _rawValue;
			}
			auto @property sign()
			{
				return _valueSign;
			}
			@property void sign(in byte new_sign);
			override string toString();
			bool opEquals(Tuple!(string, string, string, ulong) t);
			T opCast(T)()
			{
				return to!T(_strValue);
			}
		}
	}
}
