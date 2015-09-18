// D import file generated from 'source/field.d'
module rbf.field;
import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.variant;
enum FieldType 
{
	FLOAT,
	INTEGER,
	DATE,
	ALPHABETICAL,
	ALPHANUMERICAL,
}
class Field
{
	private 
	{
		FieldType _fieldType;
		string _name;
		immutable string _description;
		immutable ulong _length;
		immutable string _type;
		string _rawValue;
		string _strValue;
		ulong _index;
		ulong _offset;
		ulong _lowerBound;
		ulong _upperBound;
		float _float_value;
		uint _int_value;
		short _value_sign = 1;
		immutable ulong _cellLength;
		Variant _convertedValue;
		public 
		{
			this(in string name, in string description, in string type, in ulong length);
			Field dup();
			@property string name();
			@property void name(string name);
			@property string description();
			@property FieldType type();
			@property string declaredType();
			@property ulong length();
			@property ulong cell_length();
			@property string value();
			@property void value(string s);
			@property string rawValue();
			@property ulong index();
			@property void index(ulong new_index);
			@property ulong offset();
			@property void offset(ulong new_offset);
			@property short sign();
			@property void sign(short new_sign);
			@property ulong lowerBound();
			@property ulong upperBound();
			@property void lowerBound(ulong new_bound);
			@property void upperBound(ulong new_bound);
			void convert();
			override string toString();
			bool isFilterMatched(in string operator, in string scalar);
			static string testFilter(in string operator);
		}
	}
}
import std.exception;
