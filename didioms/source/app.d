import std.stdio;
import std.container;
import std.conv;
import std.algorithm;
import std.string;
import std.process;
import std.range;
import std.datetime;
import std.concurrency;
import std.regex;

void spawnedFunction()
{
    int result=0;
    File f = File("toto.txt", "w");

    while (result != 1)
    {
        receive(
                (string s) { f.write(s); },
                (int i) { 
                    writefln("Received i=%d, ending thread", i); 
                    result = i;
                },
               );
    }
    f.close;
}

string buildRegex(string s)
{
    auto r = "%s.*\\n".format(s);
    return r;
}

void main(string[] argv)
{

    /*
    File fh = File(argv[1], "r");

    auto fl = buildRegex("FL");
    auto lg = buildRegex("LG");
    auto sg = buildRegex("SG");

    auto fmt = "(%s)(?:((%s)((%s)+)))+".format(fl, lg, sg);
    writeln(fmt);

    auto r = regex(fmt, "m");

    foreach (ubyte[] buffer; fh.byChunk(4096))
    {
        auto s = cast(char[])buffer;
        auto m = matchAll(s, r);
        if (!m.empty)
        {
            foreach (i; 1 .. m.captures.length)
            {
                writefln("%d: <%s>", i, m.captures[i].strip);
            }
            writeln("******************************");
        }
    }

    fh.close;
    */

    /*

int i = 100;
string s = " this is a string   ";

    writefln("<%0.*d>", 10, i);
    writefln("<%10.*d>", 10, i);
    writefln("<%*.*s>", 30, 30, s.strip);
    writefln("<%-*.*s>", 30, 30, s.strip);

    */

    auto s1 = argv[1], s2 = argv[2];
    auto l = to!ulong(to!double(s1));
    auto f = to!double(s2);
    writefln("l=<%d>, f=<%11.11g>", l, f);

}
