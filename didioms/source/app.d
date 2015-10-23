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



//
// struct OverpunchedInt {
//
// 	alias InnerType = int;
//
// 	static string preconv(string s) {
// 		static string posTable = makeTrans("{ABCDEFGHI}", "01234567890");
// 		static string negTable = makeTrans("JKLMNOPQR", "123456789");
//
// 		string trans;
//
// 		// found {ABCDEFGHI} in s: need to translate
// 		if (s.indexOfAny("{ABCDEFGHI}") != -1) {
// 			trans = translate(s, posTable);
// 		}
// 		else if (s.indexOfAny("JKLMNOPQR") != -1) {
// 			trans = translate(s, negTable);
// 		}
// 		return trans;
// 	}
// }

mixin template FieldTypeCore()
{
	string pattern;								/// layout moniker
	string format;    						/// layout description
}

class CoreFieldType {
	mixin FieldTypeCore;

	abstract string preconv(string s);
	abstract T conv(T)(string);

}

class FieldType(T) : CoreFieldType {

	static if (is(T == struct) && __traits(hasMember, T, "preconv")) {
	//static if (is(T == OverpunchedInt)) {
		alias InnerType = T.InnerType;
		override preconv = T.preconv;
		//static string preconv(string s) { return OverpunchedInt.preconv(s); }
		//static InnerType conv(string s) { return to!InnerType(s); }
	} else static if (__traits(isArithmetic, T) || is(T == string))
	{
pragma(msg, "here===========");
		override string preconv(string s) { return s; }
		override T conv(T)(string s) { return to!T(s); }
	}
	else static assert(false, "Type %s is not supported in FieldType".format(T.stringof));

}


// class FieldType(T) {
//
// 	mixin FieldTypeCore;
//
// 	static if (is(T == struct) && __traits(hasMember, T, "preconv")) {
// 	//static if (is(T == OverpunchedInt)) {
// 		alias InnerType = T.InnerType;
// 		alias preconv = T.preconv;
// 		//static string preconv(string s) { return OverpunchedInt.preconv(s); }
// 		static InnerType conv(string s) { return to!InnerType(s); }
// 	} else static if (__traits(isArithmetic, T) || is(T == string))
// 	{
// 		alias InnerType = T;
// 		static T conv(string s) { return to!T(s); }
// 	}
// 	else static assert(false, "Type %s is not supported in FieldType".format(T.stringof));
//
// }

//
// class Element(T,U) {
// 	T name;
// 	U length;
//
// 	this(string name, ulong length) {
// 		this.name = name; this.length = length;
// 	}
//
// 	abstract @property void value(string s);
// 	abstract @property string value();
//
// }
//
//
// class Field(T) : Element!(string, ulong)
// {
// private:
// 	string _strValue;
// 	string _rawValue;
// 	T.InnerType _value;
// 	T _fieldType;
// 	pragma(msg, "===> inner type is ", T.InnerType.stringof);
//
// public:
// 	this(string name, ulong length) {
// 		super(name, length);
// 	}
//
// 	//@property T.InnerType convValue() { return _value; }
// 	override @property string value() { return _strValue; }
//
// 	override @property void value(string s)
// 	{
// 		_rawValue = s;
//
// 		//static if (is(T == FieldType!OverpunchedInt)) {
// 		static if (__traits(hasMember, T, "preconv")) {
// 			_strValue = T.preconv(s.strip);
// 		}
// 		else {
// 			_strValue = s.strip;
// 		}
// 		_value = T.conv(_strValue);
// 	}
// }
//
//



pragma(msg, "__traits(isScalar, int): ", __traits(isArithmetic, int));
pragma(msg, "__traits(isScalar, float): ", __traits(isArithmetic, float));
pragma(msg, "__traits(isScalar, string): ", __traits(isArithmetic, string));
//pragma(msg, "__traits(isScalar, overpunchedInt): ", __traits(isArithmetic, OverpunchedInt));






void main(string[] argv)
{

// auto f1 = new Field!(FieldType!string)("FIELD1", 10);
// auto f2 = new Field!(FieldType!int)("FIELD2", 10);
// auto f3 = new Field!(FieldType!OverpunchedInt)("FIELD3", 10);
//auto f4 = new Field!(FieldType!Date);

// Element!(string,ulong)[] tab;
//
// 		tab ~= new Field!(FieldType!string)("FIELD1", 10);
// 		tab ~= new Field!(FieldType!int)("FIELD2", 10);
// 		tab ~= new Field!(FieldType!OverpunchedInt)("FIELD3", 10);
//
// 		tab[0].value = "ggg ";
// 		tab[1].value = "  123 ";
// 		tab[2].value = "   6{}  ";
//
// 		foreach (f; tab) {
// 			write("field name = ", f.name);
// 			writeln("value = ", f.value);
// 		}

CoreFieldType[string] map;

	//CoreFieldType c1 = new FieldType!int;

	map["int"] = new FieldType!int;
	map["string"] = new FieldType!string;


}
