import std.stdio;
import std.container;
import std.conv;
import std.algorithm;
import std.string;
import std.process;
import std.range;
import std.datetime;
//import std.typecons;

void read_string(string fn)
{
  int i=0;
  string s;
  foreach (string line_read; lines(File(fn)))
  {
    s = line_read.strip;
  }
}

void read_array(string fn)
{
  int i=0;
  char[] s;


  File fh = File(fn);

  foreach (char[] line_read; fh.byLine)
  {
    s = line_read.strip;
  }
}

void read_byChunk(string fn)
{
  int i=0;
  ubyte[] s;


  File fh = File(fn);

  foreach (ubyte[] line_read; fh.byChunk(4096))
  {
    //line_read.splitter('\n').each!(e => e.strip);
  }
}

void read_ln(string fn)
{
  int i=0;



  File fh = File(fn);

  char[] buf;

  while (fh.readln(buf)) {
    auto s = buf.strip;
  }
}



class A {



  //struct Range {

    private:

      File fh;
      ulong nbChars = ulong.max;
      char[] buffer;
      string fn;
      char [] lineRead;



    public:

      this(string fn) {
          fh = File(fn);
writefln("fh=%s", fh);
      }

      @property bool empty() const { return nbChars == 0; }
  		@property ref char[] front() {
        nbChars = fh.readln(buffer);
        return buffer;
      }
  		void popFront() { {} }


  //}



}


void main(string[] argv)
{
void f0() { read_string(argv[1]); }
void f1() { read_array(argv[1]); }
void f2() { read_ln(argv[1]); }

  auto r = benchmark!(f0, f1, f2)(to!int(argv[2]));
  auto f0Result = to!Duration(r[0]);
  auto f1Result = to!Duration(r[1]);
  auto f2Result = to!Duration(r[2]);

  writefln("Time for f0 (with strings): %s for %s loops", f0Result, argv[2]);
  writefln("Time for f1 (with array): %s for %s loops", f1Result, argv[2]);
  writefln("Time for f2 (with byChunk): %s for %s loops", f2Result, argv[2]);


/*
  auto fh = File(argv[1]);

  char[] buf;

  while (fh.readln(buf)) {
    writeln(buf);
  }
*/

}
