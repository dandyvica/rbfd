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

  string _fn;

  this(string fn) {
    _fn = fn;
  }


  struct Range {

    private:

      File fh;
      ulong nbChars = ulong.max;
      char[] buffer;
      string fn;
      char [] lineRead;



    public:

      this(string fn) {
          fh = File(fn);
          nbChars = fh.readln(buffer);
      }

      @property bool empty() const { return nbChars == 0; }
  		@property string front() {
        return buffer.dup.strip;
      }
  		void popFront() {
        do {
          nbChars = fh.readln(buffer);
          if (nbChars == 0) return;
        } while (buffer[0] == '#');
      }

    }

    /// Return a range on the container
  	Range opSlice() {
  		return Range(_fn);
  	}

}


void main(string[] argv)
{
/*
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
*/

  auto a = new A(argv[1]);

/*
  foreach (l; a) {
    writefln("l=<%s>", l);
  }*/

  a[].filter!(e => !e.startsWith("1")).each!(e => writeln(e));
  a[].filter!(e => !e.startsWith("1")).map!(e => "=>" ~ e).each!(e => writeln(e));

}
