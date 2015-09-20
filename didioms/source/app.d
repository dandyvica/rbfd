import std.stdio;
import std.container.array;
import std.conv;
import std.algorithm;
import std.string;
import std.process;

class F {

	File _fh;
	char[] line;

	this(string fn) {
		_fh = File(fn, "r");
	}

	bool empty() { return _fh.eof; }
	ref char[] front() {
		_fh.readln(line);
		//line.length = line.length-1;
	 	return line;
	}
	void popFront() { }


}

void main(string[] argv)
{
	char[] line;
	auto fh = File(argv[1]);
	while (!fh.eof) {
		writef("before readln eof=%s, ", fh.eof);
		fh.readln(line,std.ascii.newline);
		writefln("line=<%s>, after readln eof=%s",chomp(line), fh.eof);
	}
	fh.close();
}


	auto f = new F(argv[1]);


	foreach (l; f) {
		writefln("2.line=<%s>",l);
	}

	foreach (l; f.filter!(s => s.length == 0)) {
		write(l);
	}




}
