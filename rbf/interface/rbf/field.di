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
import rbf.fieldtype;
class Field
{
	private 
	{
		FieldType _fieldType;
		string _name;
		immutable string _description;
		immutable ulong _length;
		string _rawValue;
		string _strValue;
		ulong _index;
		ulong _offset;
		ulong _lowerBound;
		ulong _upperBound;
		byte _valueSign = 1;
		immutable ulong _cellLength;
		public 
		{
			this(in string name, in string description, FieldType ftype, in ulong length);
			this(in string name, in string description, in string stringType, in ulong length);
			@property string name();
			@property string description();
			@property FieldType fieldType();
			@property ulong length();
			@property ulong cellLength();
			@property string value();
			@property T value(T)()
			{
				return to!T(_strValue) * sign;
			}
			@property void value(string s);
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
			string toXML();
			bool isFieldFilterMatched(in string op, in string rvalue);
			bool opEquals(Tuple!(string, string, string, ulong) t);
		}
	}
}
