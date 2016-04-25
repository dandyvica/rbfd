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
import rbf.builders.xmlcore;
alias TVALUE = string;
pragma (msg, "========> TVALUE = ", TVALUE.stringof);
struct ContextualInfo
{
	size_t index;
	size_t offset;
	size_t occurence;
	size_t lowerBound;
	size_t upperBound;
	typeof(Field.name) alternateName;
}
class Field : Element!(string, size_t, ContextualInfo)
{
	private 
	{
		FieldType _fieldType;
		TVALUE _rawValue;
		TVALUE _strValue;
		byte _valueSign = 1;
		Regex!char _fieldPattern;
		string _charPattern;
		string _format;
		public 
		{
			this(in string name, in string description, FieldType type, in size_t length)
			{
				super(name, description, length);
				context.alternateName = name;
				_fieldType = type;
				pattern = type.meta.pattern;
				_format = type.meta.format;
			}
			this(string[string] attr)
			{
				enforce("name" in attr, MSG084);
				enforce("description" in attr, MSG085);
				enforce("length" in attr, MSG086);
				enforce("type" in attr, MSG087);
				this(attr["name"], attr["description"], new FieldType(attr["type"], "string"), to!size_t(attr["length"]));
			}
			this(in string csvdata, string delimiter = ";")
			{
				auto f = csvdata.split(delimiter);
				enforce(f.length == 5, MSG010.format(f.length, 5));
				this(f[0], f[1], new FieldType(f[2], f[3]), to!size_t(f[4]));
			}
			@property FieldType type()
			{
				return _fieldType;
			}
			@property void pattern(in string s)
			{
				_charPattern = s;
				_fieldPattern = regex(s);
			}
			@property string pattern()
			{
				return _charPattern;
			}
			bool matchPattern()
			{
				return !matchAll(_strValue.strip, _fieldPattern).empty;
			}
			@property void fieldFormat(in string s)
			{
				_format = s;
			}
			@property string fieldFormat()
			{
				return _format;
			}
			auto @property value()
			{
				return _strValue;
			}
			void setFormattedValue(char[] s)
			{
				_rawValue = _fieldType.meta.formatterCallback(s, length);
			}
			@property T value(T)()
			{
				return to!T(_strValue) * sign;
			}
			@property void value(TVALUE s)
			{
				_rawValue = s;
				if (type.meta.preConv)
				{
					_strValue = type.meta.preConv(s.strip);
				}
				else
					_strValue = s.strip;
			}
			auto @property rawValue()
			{
				return _rawValue;
			}
			auto @property sign()
			{
				return _valueSign;
			}
			@property void sign(in byte new_sign)
			{
				_valueSign = new_sign;
			}
			string asXML()
			{
				XmlAttribute[] attributes;
				attributes ~= XmlAttribute("name", name);
				attributes ~= XmlAttribute("description", description);
				attributes ~= XmlAttribute("length", to!string(length));
				attributes ~= XmlAttribute("type", type.meta.name);
				return buildXmlTag("field", attributes);
			}
			override string toString()
			{
				with (context)
				{
					return MSG003.format(name, description, length, type, lowerBound, upperBound, rawValue, value, offset, index);
				}
			}
			auto contextualInfo()
			{
				return "name=<%s>, alternateName=<%s>, index=<%d>, offset=<%d>".format(name, context.alternateName, context.index + 1, context.offset + 1);
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
