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

    File fh = File(argv[1], "r");

    auto txhs = buildRegex("TXHS");
    auto txrs = buildRegex("TXRS");
    auto txcs = buildRegex("TXCS");
    auto txws = buildRegex("TXWS");

    auto fmt = "(%s)((%s)((?:%s)+)((?:%s)*))+".format(txhs, txrs, txcs, txws);

    auto r = regex(fmt, "m");

    foreach (ubyte[] buffer; fh.byChunk(4096))
    {
        auto s = cast(char[])buffer;
        auto m = matchAll(s, r);
        if (!m.empty)
        {
            writefln("<%s>", m.captures[1].strip);
            writefln("<%s>", m.captures[2].strip);
            writefln("<%s>", m.captures[3].strip);
            writefln("<%s>", m.captures[4].strip);
            writeln("******************************");
        }
    }

    fh.close;
}
