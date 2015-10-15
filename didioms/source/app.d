import std.stdio;
import std.container;
import std.conv;
import std.algorithm;
import std.string;
import std.process;
import std.range;
import std.datetime;
//import std.typecons;


void main(string[] argv)
{

	string x = "writeflnTime for f0 (with strings): %s";

	auto a = to!size_t(argv[1]);
	auto b = to!size_t(argv[2]);


	auto f = (size_t a, size_t b, string x) => x[a..b];

	writeln(f(a,b,x));

}
