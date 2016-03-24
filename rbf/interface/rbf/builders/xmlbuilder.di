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
	struct
	{
		Regex!char _fieldRegex;
		string _fieldRegexChar;
		Regex!char _recordRegex;
		string _recordRegexChar;
	}
	this();
	@property void fieldRegex(in string re);
	@property string fieldRegex();
	@property void recordRegex(in string re);
	@property string recordRegex();
	string[string] isRecordMatched(string s);
	string[string] isFieldMatched(string s);
	private string[string] _isMatchingRegex(string s, Regex!char re);
}
