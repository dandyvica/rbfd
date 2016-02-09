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
        // get back attributes
        auto attr = tuple(__traits(getAttributes, __traits(getMember, cmdLineOptions, member)));

        // just one UDA? it's the option string
        if (attr.length == 1)
        {
            getopt(argv, config.passThrough, 
                    attr[0], &__traits(getMember, cmdLineOptions, member));
        }
        // 2 UDAs ? it's the option string as a mandatory argument
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

// split data which can be passed from the command line or
// from a text file into individual match objetcs
auto splitIntoAtoms(string data, string separator, Regex!char regex)
{
    // this will kepp all Captures() objects
    RegexMatch!string[] c;

    // first, split into individual tags. Ex: "a=1;b= 3;# this is a comment"
    // into ["a=1", "b= 3"]
    auto tags = splitIntoTags(data, separator);

    // now split each individual tag into sub tags
    foreach (tag; tags)
    {
        c ~= matchAll(tag, regex);
    }

    // return our array
    return c;
    
}
unittest {
    auto s = "a=1;b= 3;# this is a comment";
    auto c = splitIntoAtoms(s, ";", regex(r"(\w+)\s*=\s*(\w+)"));
    assert(!c[0].empty);
    assert(c[0].captures[1] == "a");
    assert(c[0].captures[2] == "1");
    assert(!c[1].empty);
    assert(c[1].captures[1] == "b");
    assert(c[1].captures[2] == "3");
}
