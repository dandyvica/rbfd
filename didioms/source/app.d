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

void main(string[] argv)
{

    /*
    File fh = File(argv[1], "r");

    if (argv[2] == "thread") 
    {
        auto tid = spawn(&spawnedFunction);
        writeln("thread version");
        foreach (string line; lines(fh))
        {
            send(tid, line);
        }

        send(tid,1);
    }
    else 
    {
        File f = File("toto.txt", "w");
        writeln("no-thread version");
        foreach (string line; lines(fh))
        {
            f.write(line);
        }
        f.close;
    }
    */

    File fh = File(argv[1], "r");
//    auto r = regex(r"(FL.*\n){1}(LG.*\n(SG.*\n){1,4}){1,4}");

    /*
    foreach (ubyte[] buffer; fh.byChunk(4096))
    {
        /*
        auto m = matchAll(cast(char[])buffer, r);
        foreach (c; m) {
            foreach (c1; c) {
            writefln("<%s>", c1);
            }
        }
        foreach (line; splitter(cast(char[])buffer, "\n"))
        {
            writeln(line);
        }
    }
*/

    auto line = new char[4096];
    auto i = 0;
 
    foreach (char ub; fh.byChunk(4096).joiner)
    {
        if (ub == '\n')
        {
            writefln("%.*s", i, line);
            i = 0;
        }
        else 
            line[i++] = ub;
    }

    fh.close;
}
