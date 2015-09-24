import std.stdio;
import std.container.array;
import std.conv;
import std.algorithm;
import std.string;
import std.process;
import std.range;
import std.typecons;


class Field {

	string name;
	ulong length;
	string value;

	this(string n) {
		name = n;
	}

	override string toString() {
		return "<name=%s, value=%s>".format(name, value);
	}
}




class FieldContainer(T) {
	alias TNAME  = typeof(T.name);
	alias TVALUE = typeof(T.value);

	T[] list;
	Tuple!(T, ulong)[][TNAME] map;


	//----------------------------------------------------------------------------
	// ctor methods
	//----------------------------------------------------------------------------
	this(ushort preAllocSize=50) { list.reserve(preAllocSize); }

	//----------------------------------------------------------------------------
	// properties
	//----------------------------------------------------------------------------

	@property ulong size() { return list.length; }
	@property ulong length() {
		return std.algorithm.iteration.sum(list.map!(e => e.length));
	}

	static string getMembersData(string memberName) {
		return "return array(list.map!(e => e." ~ memberName ~ "));";
	}


	TNAME[] t() { mixin(getMembersData("name")); }

	//----------------------------------------------------------------------------
	// add methods
	//----------------------------------------------------------------------------

	void opOpAssign(string op)(T element) if (op == "~")
	{
		list ~= element;
		map[element.name] ~= tuple(element, list.length-1);
	}

	//----------------------------------------------------------------------------
	// index methods
	//----------------------------------------------------------------------------

	T opIndex(size_t i) { return list[i]; }
	T[] opIndex(TNAME name) { return array(map[name].map!(e => e[0])); }
	T[] opSlice(size_t i, size_t j) { return list[i..j]; }
	ulong[] index(TNAME name) { return array(map[name].map!(e => e[1])); }

	///
/*
	size_t[] index(string name) {

	}*/

  //----------------------------------------------------------------------------
	// remove methods
	//----------------------------------------------------------------------------

	/// remove a single element at index i
	void remove(size_t i) {
		/// first get its name
		list = list.remove(i);

		// find its index in the map to remove it also here
		auto name = this[i].name;
		map[name] = map[name].remove!(e => e[1] == i);
	}

	/// remove all elements matching name (as the same name may appear several times)
	void remove(TNAME name) {
		list = list.remove!(f => f.name == name);

		// remove corresponding key
		map.remove(name);
	}

	/// remove all elements in the list
	void remove(TNAME[] name) { name.each!(e => this.remove(e)); }

	/// remove all elements not in the list
	void keep(TNAME[] name) {
		list = array(list.filter!(e => name.canFind(e.name)));
		auto keys = map.keys.filter!(e => !name.canFind(e));
		keys.each!(e => map.remove(e));
	}

	//----------------------------------------------------------------------------
	// reduce methods
	//----------------------------------------------------------------------------

	// sum of elements converted to type U
	U sum(U)(TNAME name) {
		return list.filter!(e => e.name == name).map!(e => to!U(e.value)).sum();
	}

	//----------------------------------------------------------------------------
	// "iterator" methods
	//----------------------------------------------------------------------------

	int opApply(int delegate(ref T) dg)
	{
		int result = 0;

		foreach (T e; list)	{
		    result = dg(e);
		    if (result)	break;
		}
		return result;
	}

	//----------------------------------------------------------------------------
	// belonging methods
	//----------------------------------------------------------------------------

	T[]* opBinaryRight(string op)(TNAME name)
	{
		static if (op == "in") { return (name in map); }
	}



	void inspect() {
		//list.each!(e => writeln(e));
	writefln("list   => %s", list);
	writefln("map    => %s", map);
	//writefln("index  => %s", index);
	}

}

/*
class FieldContainerRange(T) {
	FieldContainer!T fields;

	this(FieldContainer!T f) { fields = f; }

	@property bool empty() const { return fields.length == 0; }
	@property ref FieldContainer!T front() { return fields[0]; }
	void popFront() { fields.popFront(); }
}

FieldContainerRange!T myRange(T)(T elem) {
	return new FieldContainerRange!T(elem);
}
*/



void main(string[] argv)
{

	auto c = new FieldContainer!Field();
	foreach (j; 1..3) {
		foreach (i; 1..6) {
			auto f = new Field("FIELD"~to!string(i));
			f.value = to!string(j-1+i*i);
			c ~= f;
		}
	}

	//writeln(c.myRange.take(2));
	c.inspect();

  writefln("\nindexes=%s\n",c.index("FIELD5"));
	writeln("\nremove"); c.remove("FIELD5"); c.inspect();
	writeln("\nremove"); c.remove("FIELD5"); c.inspect();
	writeln("\nremove"); c.remove(["FIELD1","FIELD3"]); c.inspect();
	writeln("\nkeep"); c.keep(["FIELD2","FIELD4"]); c.inspect();

	writefln("\nsum: %f", c.sum!float("FIELD2"));
	c.inspect();

	writeln("postblit");
	auto d = c;

	d.each!(e => e.value = "1");

	foreach (e; d) {
		writeln(e);
	}
	d.inspect;

	writeln("\nremove(i)");
	d.remove(0);

	d.inspect();



}
