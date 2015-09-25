import std.stdio;
import std.container.array;
import std.conv;
import std.algorithm;
import std.string;
import std.process;
import std.range;
//import std.typecons;


class Field {

	string name;
	ulong length;
	string value;
	ulong index;

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
	T[][TNAME] map;

public:
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
		map[element.name] ~= element;
	}

	//----------------------------------------------------------------------------
	// index methods
	//----------------------------------------------------------------------------

	T opIndex(size_t i) { return list[i]; }
	T[] opIndex(TNAME name) { return map[name]; }
	T[] opSlice(size_t i, size_t j) { return list[i..j]; }

  //----------------------------------------------------------------------------
	// remove methods
	//----------------------------------------------------------------------------

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

	// get the maximum of all elements converted to type U
	U max(U)(TNAME name) {
		auto values = list.filter!(e => e.name == name).map!(e => to!U(e.value));
		return values.reduce!(std.algorithm.comparison.max);
	}

	// get the minimum of all elements converted to type U
	U min(U)(TNAME name) {
		auto values = list.filter!(e => e.name == name).map!(e => to!U(e.value));
		return values.reduce!(std.algorithm.comparison.min);
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

	//----------------------------------------------------------------------------
	// misc. methods
	//----------------------------------------------------------------------------

	// count number of elements having the same name
	auto count(TNAME name) { return list.count!("a.name == b")(name); }



	void inspect() {
		//list.each!(e => writeln(e));
	writefln("list   => %s", list);
	writefln("map    => %s", map);
	//writefln("index  => %s", index);
	}

	//----------------------------------------------------------------------------
	// private methods
	//----------------------------------------------------------------------------


}


class FieldContainerRange(T) {
	FieldContainer!T items;

	ulong head = 0;
	ulong tail = 0;

	this(FieldContainer!T f) {

			items = f;
			head = 0;
			tail = f.length - 1;

	}

	@property bool empty() const { return items.list.length == head; }
	@property ref T front() { return items.list[head]; }
	@property ref T back() { return items.list[tail]; }
	void popBack() {  tail--; }
	void popFront() {
/*
		auto name = items.list[0].name;
		items.list.remove(0);
		items.map[name].remove(0);

		auto name = items.list[0].name;
		items.list = items.list[1..$];
		items.map[name] = items.map[name][1..$];

		if (items.map[name] == []) items.map.remove(name);*/
		head++;
 	}

}



class S {

	string[] list;

	Range r;

	struct Range {
		string[] items;

		ulong head = 0;
		ulong tail = 0;

		this(string[] list) {

				items = list;
				head = 0;
				tail = list.length - 1;

		}

		@property bool empty() const { return items.length == head; }
		@property ref string front() { return items[head]; }
		@property ref string back() { return items[tail]; }
		void popBack() {  tail--; }
		void popFront() {	head++;	}
	}

	this(string[] l) {
		list = l.dup;

		r = Range(list);
	}

	@property Range range() { return r; }

	override string toString() { return join(list, "-"); }


}









void main(string[] argv)
{

/*
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

  //writefln("\nindexes=%s\n",c.index("FIELD5"));
	writeln("\nremove"); c.remove("FIELD5"); c.inspect();
	writeln("\nremove"); c.remove("FIELD5"); c.inspect();
	writeln("\nremove"); c.remove(["FIELD1","FIELD3"]); c.inspect();
	writeln("\nkeep"); c.keep(["FIELD2","FIELD4"]); c.inspect();

	writefln("\ncount: %d", c.count("FIELD2"));

	writefln("\nsum: %f", c.sum!float("FIELD2"));
	writefln("\nmax: %f", c.max!float("FIELD2"));
	c.inspect();

	writeln("postblit");
	auto d = c;

	d.each!(e => e.value = "1");

	foreach (e; d) {
		writeln(e);
	}
	d.inspect;

	writeln("------------------------------------------------------------");

	auto e = new FieldContainer!Field();
	e ~= new Field("FIELD_A");
	e ~= new Field("FIELD_B");
	e ~= new Field("FIELD_B");
	e ~= new Field("FIELD_A");
	e ~= new Field("FIELD_C");
	e ~= new Field("FIELD_B");
	auto r = new FieldContainerRange!Field(e);
	//e.inspect;
	//writeln(r);
	//e.inspect;
	writeln(r.drop(3));
	e.inspect;
*/

	auto s = new S(["FIELD_A", "FIELD_B", "FIELD_A", "FIELD_B", "FIELD_C"]);
	writeln(s);

	s.range.each!writeln;
	writeln(s.range.filter!(a => a.endsWith("_A")));
	writeln(s.range.filter!(a => a.endsWith("_C")));

}
