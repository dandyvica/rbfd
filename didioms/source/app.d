import std.stdio;
import std.container.array;
import std.conv;
import std.algorithm;
import std.string;

void main()
{

	// slist
  string[] list;

	foreach (i; 1..10) {
		list ~= "item_" ~ to!string(i%3);
	}

	writeln(list);

	list = list.remove!(s => s == "item_0");
	writeln(list);

	auto s1 = "ssssssssssssss";
	writefln("<%s>", s1.leftJustify(30));

	auto s2 = "ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss";
	writefln("<%s>", s2.leftJustify(30));

}
