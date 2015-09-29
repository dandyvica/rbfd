import std.stdio;
import std.container;
import std.conv;
import std.algorithm;
import std.string;
import std.process;
import std.range;
//import std.typecons;





void main(string[] argv)
{

auto l = new SList!string(["a", "b", "c", "d", "e", "f", "g", "h", "i"]);

	auto f = l[].filter!(e => e == "a");


}
