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
	this()
	{
	}
	@property void fieldRegex(in string re)
	{
		_fieldRegex = regex(re);
		_fieldRegexChar = re;
	}
	@property string fieldRegex()
	{
		return _fieldRegexChar;
	}
	@property void recordRegex(in string re)
	{
		_recordRegex = regex(re);
		_recordRegexChar = re;
	}
	@property string recordRegex()
	{
		return _recordRegexChar;
	}
	string[string] isRecordMatched(string s)
	{
		return _isMatchingRegex(s, _recordRegex);
	}
	string[string] isFieldMatched(string s)
	{
		return _isMatchingRegex(s, _fieldRegex);
	}
	private string[string] _isMatchingRegex(string s, Regex!char re)
	{
		string[string] capturedData;
		auto m = matchAll(s, re);
		if (m.empty)
			return null;
		foreach (nc; re.namedCaptures)
		{
			capturedData[nc] = m.captures[nc];
		}
		return capturedData;
	}
}
