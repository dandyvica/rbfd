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
import std.socket;
import std.getopt;
import std.typecons;

struct Cmd {
    @("i") @(config.required) int a;
    @("f") string file;
}

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
    writefln("<%-*.*s>", 30, 30, sr;.strip);

    */

    Cmd cmd;

    foreach (member; __traits(allMembers, Cmd))
    {
        writefln("member = %s ", member);
        auto attr = tuple(__traits(getAttributes, __traits(getMember, Cmd, member)));
        writefln("==> %s", attr);
        if (attr.length == 1)
        {
            getopt(argv, config.passThrough, attr[0], &__traits(getMember, cmd, member));
        }
        if (attr.length == 2)
        {
            getopt(argv, config.required, config.passThrough, attr[0], &__traits(getMember, cmd, member));
        }
        /*
        foreach (attr; __traits(getAttributes, __traits(getMember, Cmd, member)))
        {
            //writef("attribute = %s ", attr);
            //getopt(argv, config.passThrough, attr, &__traits(getMember, cmd, member));
            writeln(argv);
        }
        writeln;
        */
    }
    
    writeln(cmd);
}


void daemon_mode() 
{
    Socket server = new TcpSocket();
    server.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
    server.bind(new InternetAddress(8080));
    server.listen(1);

    while(true) {
        Socket client = server.accept();

        char[1024] buffer;
        auto received = client.receive(buffer);

        writefln("The client said:\n%s", buffer[0.. received]);

        enum header =
            "HTTP/1.0 200 OK\nContent-Type: text/html; charset=utf-8\n\n";

        string response = header ~ "Hello World!\n";
        client.send(response);

        client.shutdown(SocketShutdown.BOTH);
        client.close();
    }
}
