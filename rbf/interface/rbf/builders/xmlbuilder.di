// D import file generated from 'source/rbf/builders/xmlbuilder.d'
module rbf.builders.xmlbuilder;
pragma (msg, "========> Compiling module ", "rbf.builders.xmlbuilder");
import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.exception;
class RbfBuilder
{
	File _fh;
	struct
	{
		Regex!char _fieldRegex;
		Regex!char _recordRegex;
	}
	this(string fn);
	@property void fieldRegex(in string re);
	@property void recordRegex(in string re);
}
