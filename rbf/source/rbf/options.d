module rbf.options;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.getopt;
import std.traits;
import std.typecons;
import std.algorithm;
import std.array;
import std.regex;

// fonction to process input parameters, from the T type which
// by convention includes the User Defined Attributes as the input
// parameters and optionnally the config.required getopt()
// parameter
void processCommandLineArguments(T)(string[] argv, ref T cmdLineOptions)
{
    foreach (member; __traits(allMembers, T))
    {
        //writefln("member = %s ", member);
        auto attr = tuple(__traits(getAttributes, __traits(getMember, cmdLineOptions, member)));
        //writefln("==> %s", attr);
        if (attr.length == 1)
        {
            getopt(argv, config.passThrough, 
                    attr[0], &__traits(getMember, cmdLineOptions, member));
        }
        if (attr.length == 2)
        {
            getopt(argv, config.required, config.passThrough, 
                    attr[0], &__traits(getMember, cmdLineOptions, member));
        }
    }
}

// split data which can be passed from the command line or
// from a text file
string[] splitIntoTags(string tags, string separator = std.ascii.newline)
{
    // split data according to separator and return a list of tags
    // by convention, all lines starting with # are considered as comments 
    auto splitted = (separator == std.ascii.newline) ? array(tags.lineSplitter) : tags.split(separator);

    // purge comments or empty data
    return array(splitted.remove!(s => s.strip == "").remove!(s => s.startsWith("#")));
}
unittest {
    auto s = "a=1;b= 3;# this is a comment";
    auto tags = splitIntoTags(s, ";");
    assert(tags == ["a=1", "b= 3"]);
}

/*
Captures!string[] splitIntoAtoms(string data, string separator, Regex!char regex)
{
    // this will kepp all Captures() objects
    Captures!string[] c;

    // first, split into individual tags. Ex: "a=1;b= 3;# this is a comment"
    // into ["a=1", "b= 3"]
    auto tags = splitIntoTags(data, separator);

    // now split each individual tag into sub tags
    foreach (tag; tags)
    {
        c ~= matchAll(tag, regex);
    }
    
}
*/
