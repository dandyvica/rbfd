// D import file generated from 'source/rbf/fieldcontainer.d'
import std.stdio;
import std.container.array;
import std.conv;
import std.algorithm;
import std.string;
import std.process;
import std.range;
import std.typecons;
class FieldContainer(T)
{
	alias TNAME = typeof(T.name);
	alias TVALUE = typeof(T.value);
	T[] list;
	Tuple!(T, ulong)[][TNAME] map;
	this(ushort preAllocSize = 50)
	{
		list.reserve(preAllocSize);
	}
	@property ulong size()
	{
		return list.length;
	}
	@property ulong length()
	{
		return std.algorithm.iteration.sum(list.map!((e) => e.length));
	}
	static string getMembersData(string memberName)
	{
		return "return array(list.map!(e => e." ~ memberName ~ "));";
	}
	TNAME[] t()
	{
		mixin(getMembersData("name"));
	}
	void opOpAssign(string op)(T element) if (op == "~")
	{
		list ~= element;
		map[element.name] ~= tuple(element, list.length - 1);
	}
	T opIndex(size_t i)
	{
		return list[i];
	}
	T[] opIndex(TNAME name)
	{
		return array(map[name].map!((e) => e[0]));
	}
	T[] opSlice(size_t i, size_t j)
	{
		return list[i..j];
	}
	ulong[] index(TNAME name)
	{
		return array(map[name].map!((e) => e[1]));
	}
	void remove(size_t i)
	{
		TNAME name = this[i].name;
		list.remove(i);
	}
	void remove(TNAME name)
	{
		list = list.remove!((f) => f.name == name);
		map.remove(name);
	}
	void remove(TNAME[] name)
	{
		name.each!((e) => this.remove(e));
	}
	void keep(TNAME[] name)
	{
		list = array(list.filter!((e) => name.canFind(e.name)));
		auto keys = map.keys.filter!((e) => !name.canFind(e));
		keys.each!((e) => map.remove(e));
	}
	U sum(U)(TNAME name)
	{
		return list.filter!((e) => e.name == name).map!((e) => to!U(e.value)).sum();
	}
	int opApply(int delegate(ref T) dg)
	{
		int result = 0;
		foreach (T e; list)
		{
			result = dg(e);
			if (result)
				break;
		}
		return result;
	}
	T[]* opBinaryRight(string op)(TNAME name)
	{
		static if (op == "in")
		{
			return name in map;
		}

	}
	void inspect()
	{
		writefln("list   => %s", list);
		writefln("map    => %s", map);
	}
}
