module rbf.options;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.getopt;
import std.traits;
import std.typecons;

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

