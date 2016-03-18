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
    File _fh;           // file handle on file to read and scan

    // use those regexes to match fields and records
    struct {
        Regex!char _fieldRegex;
        Regex!char _recordRegex;
    }


    this(string fn)
    {
        _fh = File(fn, "r");
    }

	/// read/write property for field & record regexes
	@property void fieldRegex(in string re) { _fieldRegex = regex(re); }
	@property void recordRegex(in string re) { _recordRegex = regex(re); }
}
    
