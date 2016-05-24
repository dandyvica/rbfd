module rbf.builders.xmlbuilder;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.exception;

class RbfBuilder 
{
    // use those regexes to match fields and records
    struct {
        Regex!char _fieldRegex;
        string _fieldRegexChar;
        Regex!char _recordRegex;
        string _recordRegexChar;
    }

    this()
    {
    }

	/// read/write property for field & record regexes
	@property void fieldRegex(in string re)  { _fieldRegex  = regex(re); _fieldRegexChar = re; }
	@property string fieldRegex()  { return _fieldRegexChar; }
	@property void recordRegex(in string re) { _recordRegex = regex(re); _recordRegexChar = re;}
	@property string recordRegex()  { return _recordRegexChar; }

    /// match a record
    string[string] isRecordMatched(string s)
    {
        return _isMatchingRegex(s, _recordRegex);
    }

    /// match a field
    string[string] isFieldMatched(string s)
    {
        return _isMatchingRegex(s, _fieldRegex);
    }


private:
    /// set is a string is matching a regex
    string[string] _isMatchingRegex(string s, Regex!char re)
    {
        string[string] capturedData;

        // get matched data
        auto m = matchAll(s, re);

        // nothing found?
        if (m.empty) return null;

        // loop on matched named groups
        foreach (nc; re.namedCaptures)
        {
            capturedData[nc] = m.captures[nc];
        }

        return capturedData;
    }

}
    
///
unittest {
    auto r = new RbfBuilder();

    r.recordRegex = r"^Part 7\.\d+ (?P<name>[A-Z]{3}/\d{2}) (?P<description>[\w\s/]+)";
    auto s = "Part 7.1 TTH/01 File Header";
    auto s1 = "xxxxxxxx";
    auto data = r.isRecordMatched(s);
    auto data1 = r.isRecordMatched(s1);

    assert(data["name"] == "TTH/01");
    assert(data["description"] == "File Header");

    assert(data1 == null);
}

