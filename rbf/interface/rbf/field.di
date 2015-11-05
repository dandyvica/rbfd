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
struct ContextualInfo
{
	ulong index;
	ulong offset;
	ulong occurence;
	ulong lowerBound;
	ulong upperBound;
	string alternateName;
}
class Field : Element!(string, ulong, ContextualInfo)
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
		string _charPattern;
		public 
		{
			this(in string name, in string description, FieldType type, in ulong length)
			{
				super(name, description, length);
				_fieldType = type;
				_charPattern = type.meta.pattern;
				_fieldPattern = regex(_charPattern);
			}
			this(in string csvdata)
			{
				auto f = csvdata.split(";");
				enforce(f.length == 5, MSG010.format(f.length, 5));
				this(f[0], f[1], new FieldType(f[2], f[3]), to!ulong(f[4]));
			}
			@property FieldType type()
			{
				return _fieldType;
			}
			@property void pattern(string s)
			{
				_charPattern = s;
				_fieldPattern = regex(s);
			}
			bool matchPattern()
			{
				return !matchAll(_rawValue.strip, _fieldPattern).empty;
			}
			@property string value()
			{
				return _strValue;
			}
			@property T value(T)()
			{
				return to!T(_strValue) * sign;
			}
			@property void value(in string s)
			{
				_rawValue = s;
				auto _strippedValue = s.strip;
				if (type.meta.preConv)
				{
					_strValue = type.meta.preConv(s.strip);
				}
				else
					_strValue = s.strip;
				if (type.meta.checkPattern)
				{
					if (_strippedValue != "" && !matchPattern)
					{
						stderr.writefln(MSG002, this, _charPattern);
					}
				}
			}
			@property string rawValue()
			{
				return _rawValue;
			}
			@property byte sign()
			{
				return _valueSign;
			}
			@property void sign(byte new_sign)
			{
				_valueSign = new_sign;
			}
			override string toString()
			{
				with (context)
				{
					return MSG003.format(name, description, length, type, lowerBound, upperBound, rawValue, value, offset, index);
				}
			}
			bool opEquals(Tuple!(string, string, string, ulong) t)
			{
				return name == t[0] && description == t[1] && type.meta.name == t[2] && length == t[3];
			}
			T opCast(T)()
			{
				return to!T(_strValue);
			}
		}
	}
}
