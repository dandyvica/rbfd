module rbf.fieldtype2;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.exception;

import rbf.element;


/***********************************
 * This field type class represents possible field types
 */
class LayoutFieldType {
private:

	Regex!char _patternRegEx;			/// the pattern the field should stick to
	string _format;

public:
	/**
 	 * creates a new type from a string type
	 *
	 * Params:
	 */
	this(string pattern, string format)
	{
		_patternRegEx = regex(pattern);
		_format = format;
	}

}

//
// class FieldType(T) : LayoutFieldType {
// private:
//
// 	string _type = T.stringof;
//
// public:
//
// 	this(string pattern, string format) { super(pattern, format); }
//
// 	@property bool isString() { return _type == "string"; }
//
// }


class Field(T) : Element!(string, ulong) {
private:
	string _strValue;
	string _rawValue;
	T _value;

public:
	@property void value(string s)
	{
		_rawValue = s;
		_strValue = s.strip();
		_value = to!T(_strValue);
	}

}
