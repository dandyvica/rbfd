import std.stdio;
import std.container.array;
import std.conv;
import std.algorithm;
import std.string;
import std.process;
import std.range;
import std.typecons;

immutable uint PRE_ALLOC_SIZE = 30;

class FieldContainer(T) {
	alias TNAME  = typeof(T.name);
	alias TVALUE = typeof(T.value);

	T[] list;
	Tuple!(T, ulong)[][TNAME] map;


	//----------------------------------------------------------------------------
	// ctor methods
	//----------------------------------------------------------------------------
	this(ushort preAllocSize=PRE_ALLOC_SIZE) { list.reserve(preAllocSize); }

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
		TNAME name = this[i].name;
		list.remove(i);
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
