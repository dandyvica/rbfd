import std.stdio;
import std.container.array;
import std.conv;
import std.algorithm;
import std.string;
import std.process;
import std.range;

class Field {

	string name;
	ulong length;

	this(string n) {
		name = n;
	}

	override string toString() { return name; }
}




class FieldContainer(T) {
	alias TNAME = typeof(T.name);

	T[] list;
	T[][TNAME] map;

	@property ulong size() { return list.length; }
	@property ulong length() {
		return sum(list.map!(e => e.length));
	}

	string getMembersData(string memberName) {
		auto s = "return array(T.map!(e => e." ~ memberName ~ "));";
		return (s);
	}



	void opOpAssign(string op)(T element) if (op == "~")
	{
		list ~= element;
		map[element.name] ~= element;
	}

	void popFront() {
		list = list[1..$];
	}

	/// slicing operators
	T opIndex(size_t i) { return list[i]; }
	T[] opIndex(TNAME name) { return map[name]; }
	T[] opSlice(size_t i, size_t j) { return list[i..j]; }

	/// remove elements
	void remove(TNAME name) {
		list = list.remove!(f => f.name == name);

		// remove corresponding key
		map.remove(name);
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
	foreach (i; 1..10) {
		c ~= new Field("FIELD"~to!string(i));
	}

	//writeln(c.myRange.take(2));

}
