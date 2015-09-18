import std.stdio;
import std.container.array;
import std.conv;
import std.algorithm;
import std.string;
import std.process;

void main()
{
interface I {
	void a();
	void b();
	void c();
}

class A : I {
	void a() { writeln("A class"); }
}

}
