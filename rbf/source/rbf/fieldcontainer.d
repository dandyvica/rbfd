module rbf.fieldcontainer;

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
package:

	alias TNAME  = typeof(T.name);
	alias TVALUE = typeof(T.value);
	alias TLENGTH = typeof(T.length);

	T[] _list;					/// track all fields within a dynamic array
	T[][TNAME] _map;		/// and as several instance of the same field can exist,
											/// need to keep track of all instances

	TLENGTH _length;		/// current length of the container when adding elements

public:
	//----------------------------------------------------------------------------
	// ctor methods
	//----------------------------------------------------------------------------
	this(ushort preAllocSize=PRE_ALLOC_SIZE) { _list.reserve(preAllocSize); }

	struct Range {
		T[] items;

		ulong head = 0;
		ulong tail = 0;

		this(T[] list) {

				items = list;
				head = 0;
				tail = list.length - 1;

		}

		@property bool empty() const { return items.length == head; }
		@property ref T front() { return items[head]; }
		@property ref T back() { return items[tail]; }
		void popBack() {  tail--; }
		void popFront() {	head++;	}
	}

	Range opSlice() {
		return Range(_list);
	}

	//----------------------------------------------------------------------------
	// properties
	//----------------------------------------------------------------------------
	@property ulong size() { return _list.length; }
	@property ulong length() { return _length; }

	//----------------------------------------------------------------------------
	// useful mapper generation
	//----------------------------------------------------------------------------
	static string getMembersData(string memberName) {
		return "return array(_list.map!(e => e." ~ memberName ~ "));";
	}

	//----------------------------------------------------------------------------
	// add methods
	//----------------------------------------------------------------------------
	void opOpAssign(string op)(T element) if (op == "~") {
		_list ~= element;
		_map[element.name] ~= element;

		// added one element, so length is greater
		_length += element.length;
	}

	//----------------------------------------------------------------------------
	// index methods
	//----------------------------------------------------------------------------
	/**
	 * [] operator to retrieve i-th element object
	 *
	 * Params:
	 *	i = index of the i-th element object to retrieve
	 *
	 * Examples:
	 * --------------
	 * auto e = fieldContainer[0]  // returns the first element object
	 * --------------
	 */
	T opIndex(size_t i) {
		assert(0 <= i && i < _list.length, "index %d is out of bounds for _list[]".format(i));
		return _list[i];
	}

	/**
	 * [] operator to retrieve field object whose name is passed as an argument
	 *
	 * Params:
	 *	name of the element to retrieve
	 *
	 * Examples:
	 * --------------
	 * auto e = fieldContainer["FIELD1"]  // returns the elemnt objects named FIELD1
	 * --------------
	 */
	T[] opIndex(TNAME name) {
		assert(name in this, "element %s is not found in container".format(name));
		return _map[name];
	}

	T[] opSlice(size_t i, size_t j) { return _list[i..j]; }

	/**
		 * get the i-th field whose is passed as argument in case of duplicate
		 * field names (starting from 0)
		 * Examples:
		 * --------------
		 * fieldContainer.get("FIELD",5) // return the field object of the 6-th field named FIELD
		 * fieldContainer.get("FIELD") // return the first field object named FIELD
		 * --------------
		 */
	T get(TNAME name, ushort index = 0)
  {
		assert(name in this, "field %s is not found in record %s".format(name));
		assert(0 <= index && index < _map[name].length, "field %s, index %d is out of bounds".format(name,index));

		return _map[name][index];
	}

	/**
	 * to match an element more easily
	 *
	 * Examples:
	 * --------------
	 * fieldContainer.FIELD1 returns the value of the fieldContainer named FIELD1
	 * --------------
	 */
	@property TVALUE opDispatch(TNAME name)()
	{
		return _map[name][0].value;
	}

	/**
	 * to match an element more easily
	 *
	 * Examples:
	 * --------------
	 * fieldContainer.FIELD(5) returns the value of the 6-th element named FIELD
	 * --------------
	 */
	TVALUE opDispatch(TNAME name)(ushort index)
	{
		//enforce(0 <= index && index < _fieldMap[fieldName].length, "field %s, index %d is out of bounds".format(fieldName,index));
		return _map[name][index].value;
	}



  //----------------------------------------------------------------------------
	// remove methods
	//----------------------------------------------------------------------------

	/// remove all elements matching name (as the same name may appear several times)
	void remove(TNAME name) {
		_list = _list.remove!(f => f.name == name);
		// remove corresponding key
		_map.remove(name);
	}

	/// remove all elements in the _list
	void remove(TNAME[] name) { name.each!(e => this.remove(e)); }

	/// remove all elements not in the _list
	void keepOnly(TNAME[] name) {
		_list = array(_list.filter!(e => name.canFind(e.name)));
		auto keys = _map.keys.filter!(e => !name.canFind(e));
		keys.each!(e => _map.remove(e));
	}

	//----------------------------------------------------------------------------
	// reduce methods
	//----------------------------------------------------------------------------
	// sum of elements converted to type U
	U sum(U)(TNAME name) {
		return _list.filter!(e => e.name == name).map!(e => to!U(e.value)).sum();
	}

	// get the maximum of all elements converted to type U
	U max(U)(TNAME name) {
		auto values = _list.filter!(e => e.name == name).map!(e => to!U(e.value));
		return values.reduce!(std.algorithm.comparison.max);
	}

	// get the minimum of all elements converted to type U
	U min(U)(TNAME name) {
		auto values = _list.filter!(e => e.name == name).map!(e => to!U(e.value));
		return values.reduce!(std.algorithm.comparison.min);
	}

	//----------------------------------------------------------------------------
	// "iterator" methods
	//----------------------------------------------------------------------------
	int opApply(int delegate(ref T) dg)	{
		int result = 0;

		foreach (T e; _list)	{
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
		static if (op == "in") { return (name in _map); }
	}

	//----------------------------------------------------------------------------
	// misc. methods
	//----------------------------------------------------------------------------
	// count number of elements having the same name
	auto count(TNAME name) { return _list.count!("a.name == b")(name); }


	void inspect() {
		//_list.each!(e => writeln(e));
	writefln("_list   => %s", _list);
	writefln("_map    => %s", _map);
	//writefln("index  => %s", index);
	}

	//----------------------------------------------------------------------------
	// private methods
	//----------------------------------------------------------------------------


}



unittest {

	import rbf.field;

	writefln("-------------------------------------------------------------");
	writeln(__FILE__);
	writefln("-------------------------------------------------------------");

		auto c = new FieldContainer!Field();
		foreach (j; 1..3) {
			foreach (i; 1..6) {
				auto f = new Field("FIELD"~to!string(i),"First field","AN",5);
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
		writeln("\nkeep"); c.keepOnly(["FIELD2","FIELD4"]); c.inspect();

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
		e ~= new Field("FIELD_A","First field","AN",5);
		e ~= new Field("FIELD_B","First field","AN",5);
		e ~= new Field("FIELD_B","First field","AN",5);
		e ~= new Field("FIELD_B","First field","AN",5);
		e ~= new Field("FIELD_A","First field","AN",5);
		e ~= new Field("FIELD_C","First field","AN",5);


}
