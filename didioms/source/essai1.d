module essai1;

import std.stdio;
import std.container;
import std.conv;
import std.algorithm;
import std.string;
import std.process;
import std.range;
import std.datetime;
import std.complex;
//import std.typecons;



struct OverpunchedInt {

	alias InnerType = int;

	static string preconv(string s) {
		static string posTable = makeTrans("{ABCDEFGHI}", "01234567890");
		static string negTable = makeTrans("JKLMNOPQR", "123456789");

		string trans;

		// found {ABCDEFGHI} in s: need to translate
		if (s.indexOfAny("{ABCDEFGHI}") != -1) {
			trans = translate(s, posTable);
		}
		else if (s.indexOfAny("JKLMNOPQR") != -1) {
			trans = translate(s, negTable);
		}
		return trans;
	}
}




class FieldType(T) {

	string _pattern;
	this(string p) {
		_pattern = p;
	}

	static if (__traits(hasMember, T, "preconv")) {
	//static if (is(T == OverpunchedInt)) {
		alias InnerType = T.InnerType;
		alias preconv = T.preconv;
		//static string preconv(string s) { return OverpunchedInt.preconv(s); }
		static InnerType conv(string s) { return to!InnerType(s); }
	}
	else
	{
		alias InnerType = T;
		static T conv(string s) { return to!T(s); }
	}

}


class Element(T,U) {
	T name;
	U length;
}

class Field(T) : Element!(string, ulong) {
private:
	string _strValue;
	string _rawValue;
	T.InnerType _value;
	pragma(msg, "===> inner type is ", T.InnerType.stringof);

public:
	@property void value(string s)
	{
		_rawValue = s;

		//static if (is(T == FieldType!OverpunchedInt)) {
		static if (__traits(hasMember, T, "preconv")) {
			_strValue = T.preconv(s.strip);
		}
		else {
			_strValue = s.strip;
		}
		_value = T.conv(_strValue);
	}
}
