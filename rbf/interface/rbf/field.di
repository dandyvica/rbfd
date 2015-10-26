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
import rbf.element;
import rbf.fieldtype;
class Field : Element!(string, ulong)
{
	private 
	{
		FieldType _fieldType;
		string _rawValue;
		string _strValue;
		ulong _index;
		ulong _offset;
		ulong _lowerBound;
		ulong _upperBound;
		byte _valueSign = 1;
		Regex!char _fieldPattern;
		public 
		{
			this(in string name, in string description, FieldType type, in ulong length);
			@property FieldType type();
			@property void pattern(string s);
			bool matchPattern();
			@property string value();
			@property T value(T)()
			{
				return to!T(_strValue) * sign;
			}
			@property void value(in string s);
			@property string rawValue();
			@property ulong index();
			@property void index(ulong new_index);
			@property ulong offset();
			@property void offset(ulong new_offset);
			@property byte sign();
			@property void sign(byte new_sign);
			@property ulong lowerBound();
			@property ulong upperBound();
			@property void lowerBound(ulong new_bound);
			@property void upperBound(ulong new_bound);
			override string toString();
			bool opEquals(Tuple!(string, string, string, ulong) t);
			T opCast(T)()
			{
				return to!T(_strValue);
			}
		}
	}
}
