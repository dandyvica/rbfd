import std.stdio;
import std.container;
import std.conv;
import std.algorithm;
import std.string;
import std.process;
import std.range;
import std.datetime;
import std.concurrency;

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

}
