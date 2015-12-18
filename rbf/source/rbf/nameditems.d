module rbf.nameditems;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.container.array;
import std.conv;
import std.algorithm;
import std.string;
import std.process;
import std.range;
import std.typecons;
import std.exception;
import std.regex;

import rbf.errormsg;

immutable uint PRE_ALLOC_SIZE = 300;

/***********************************
 * Generic container for field-like objects
 */
class NamedItemsContainer(T, bool allowDuplicates, Meta...) {
private:

	string _containerName;

protected:

	// first verify essential properties existence
	// for .name: name is mandatory for T
	static if (!__traits(hasMember, T, "name")) 
    {
		pragma(msg, "error: %s class has no <%s> member".format(T.stringof, "name"));
	}
	else
		alias TNAME   = typeof(T.name);				/// alias for name property type

	// for .length: length is optional for T
	static if (__traits(hasMember, T, "length")) 
    {
		alias TLENGTH = typeof(T.length);
		TLENGTH _length;		/// current length of the container when adding elements
	}

	// aliases for managing core container data
	alias TLIST   = T[];
	alias TMAP	  = T[][TNAME];

	// useful type alias whether the container accepts duplcates or not
	static if (allowDuplicates) 
    {
		alias TRETURN = TLIST;
		ref TRETURN _contextMap(T[][TNAME] map, TNAME name) { return map[name]; }
	}
	else 
    {
		alias TRETURN = T;
		ref TRETURN _contextMap(T[][TNAME] map, TNAME name) { return map[name][0]; }
	}

	/// these are the core container store
	TLIST _list;				/// track all fields within a dynamic array
	TMAP _map;					/// and as several instance of the same field can exist,
								/// need to keep track of all instances

public:
    static if (Meta.length > 0) 
    {
        Meta[0] meta;
    }

	// inner structure for defining a range for our container
	struct Range 
    {
		private TLIST items;

		size_t head = 0;
		size_t tail = 0;

		this(TLIST list) 
        {
				items = list;
				head = 0;
				tail = list.length - 1;
		}

		@property bool empty() const { return items.length == head; }
		@property ref T front() { return items[head]; }
		@property ref T back() { return items[tail]; }
		@property Range save() { return this; }
		void popBack() {  tail--; }
		void popFront() {	head++;	}

		T opIndex(size_t i) { return items[i]; }
	}


	/**	Constructor taking an optional parameter

	Params:
	preAllocSize = preallocation of the inner array

	*/
	this(string name = "") 
    {
		_containerName = name;
		_list.reserve(PRE_ALLOC_SIZE);
	}

	/**	Constructor taking an input range

	Params:
	r = range

	*/
	this(Range)(Range r) 
    {
		this();
		foreach (e; r) 
        {
			this ~= e;
		}
	}

	//----------------------------------------------------------------------------
	// properties
	//----------------------------------------------------------------------------
	/// Get container name
	@property string name() { return _containerName; }

	/// Get container number of elements
	@property auto size() { return _list.length; }

	/// Get container number of elements for name
	@property auto size(string name) { return _map[name].length; }

	/// get length of all elements
	static if (__traits(hasMember, T, "length")) {
		@property TLENGTH length() { return _length; }
	}

	//----------------------------------------------------------------------------
	// useful mapper generation
	//----------------------------------------------------------------------------
	static string getMembersData(string memberName) {
		return "return array(_list.map!(e => e." ~ memberName ~ "));";
	}

	/// Return all elements names
	TNAME[] names() { mixin(getMembersData("name")); }

	//----------------------------------------------------------------------------
	// add methods
	//----------------------------------------------------------------------------
	/// append a new element
	void opOpAssign(string op)(T element) if (op == "~") 
    {
		// if no duplicates is allowed, need to test it
		static if (!allowDuplicates) 
        {
			enforce(element.name !in _map, MSG032.format(element.name));
		}

		// add element
		_list ~= element;
		_map[element.name] ~= element;

		// added one element, so length is greater
		static if (__traits(hasMember, T, "length")) _length += element.length;
	}

	//----------------------------------------------------------------------------
	// index methods
	//----------------------------------------------------------------------------
	/**
	 * [] operator to retrieve i-th element
	 *
	 * Params:
	 *	i = index of the i-th element to retrieve

	 Returns:

	 An element of type T

	 */
	T opIndex(size_t i) 
    {
		enforce(0 <= i && i < _list.length, MSG033.format(i));
		return _list[i];
	}

	/**
	* [] operator to retrieve field object whose name is passed as an argument
	*
	* Params:
	* name = name of the element to retrieve

	 Returns:
	 An array of elements of type T
	 */
	ref TRETURN opIndex(TNAME name) {
		enforce(name in this, MSG001.format(name, this.name));
		return _contextMap(_map, name);
	}

	/**

	Slicing operating

	Params:
	i = lower index
	j = upper index

	Returns:
	An array of elements of type T

	*/
	T[] opSlice(size_t i, size_t j)
	{
		enforce(0 <= i && i < size, MSG007.format(i,size));
		enforce(0 <= j && j <= size, MSG008.format(j,size));
		enforce(i <= j, MSG009.format(i,j));

		return _list[i..j];
	}

	/// Return a range on the container
	Range opSlice() 
    {
		return Range(_list);
	}

	/**
		 * get the i-th field whose is passed as argument in case of duplicate
		 * field names (starting from 0)

		 Returns:
		 An array of elements of type T

	*/
	T get(TNAME name, ushort index = 0)
    {
		enforce(name in this, MSG001.format(name));
		enforce(0 <= index && index < _map[name].length, MSG005.format(name,index));

		static if (!allowDuplicates) 
        {
			enforce(index == 0, MSG006.format(index));
		}

		return _map[name][index];
	}

    //----------------------------------------------------------------------------
	// remove methods
	//----------------------------------------------------------------------------

	/** remove all elements matching name (as the same name may appear several times)

	Params:
	name = name of the elements to remove

	*/
	void remove(TNAME name) 
    {
		// check if name if really in container
		enforce(name in this, MSG001.format(name, this.name));

        // remove all elements matching name
		_list = _list.remove!(f => f.name == name);

		// remove corresponding key
		_map.remove(name);
	}

	/// remove a single occurence of an element
	void remove(TNAME name, size_t index) 
    {
		enforce(name in this, MSG001.format(name));
		enforce(0 <= index && index < _map[name].length, MSG005.format(name,index));

		static if (!allowDuplicates) {
			enforce(index == 0, MSG006.format(index));
		}

		// remove from main list. Find its real index in the list array
		size_t i,j;
		foreach (e; this) { if (e.name == name && j++ == index) break; i++; }
		_list = _list.remove(i);

		// remove corresponding element in map
		_map[name] = _map[name].remove(index);
	}

	/// remove all elements in the list
	void remove(TNAME[] name) { name.each!(e => this.remove(e)); }

	/// remove all elements not in the list i.e. keep only those fields in the list
	void keepOnly(TNAME[] name) 
    {
		// check that all element names are in container
		name.each!(
			e => enforce(e in this, MSG001.format(e, this.name))
		);

		// rebuild list
		_list = array(_list.filter!(e => name.canFind(e.name)));

		// and map
		auto keys = _map.keys.filter!(e => !name.canFind(e));
		keys.each!(e => _map.remove(e));
	}

	//----------------------------------------------------------------------------
	// reduce methods
	//----------------------------------------------------------------------------
	/// Returns the sum of elements converted to type U
	U sum(U)(TNAME name) 
    {
		return _list.filter!(e => e.name == name).map!(e => to!U(e.value)).sum();
	}

	/// get the maximum of all elements converted to type U
	U max(U)(TNAME name) 
    {
		auto values = _list.filter!(e => e.name == name).map!(e => to!U(e.value));
		return values.reduce!(std.algorithm.comparison.max);
	}

	/// get the minimum of all elements converted to type U
	U min(U)(TNAME name) 
    {
		auto values = _list.filter!(e => e.name == name).map!(e => to!U(e.value));
		return values.reduce!(std.algorithm.comparison.min);
	}

	//----------------------------------------------------------------------------
	// "iterator" methods
	//----------------------------------------------------------------------------
	// foreach loop on sorted items by name
	int sorted(int delegate(ref TRETURN) dg)
	{
		int result = 0;

		foreach (TNAME name; sort(_map.keys)) 
        {
				result = dg(_contextMap(_map, name));
				if (result)
					break;
		}
		return result;
	}

	//----------------------------------------------------------------------------
	// belonging methods
	//----------------------------------------------------------------------------
    // classic in method
	TLIST* opBinaryRight(string op)(TNAME name)	if (op == "in")
	{
		return (name in _map);
	}

	//----------------------------------------------------------------------------
	// misc. methods
	//----------------------------------------------------------------------------
	/// count number of elements having the same name
	//auto count(TNAME name) { return _list.count!("a.name == b")(name); }
	auto count(TNAME name)
	{
		enforce(name in this, MSG001.format(name, this.name));
		return _map[name].length;
	}

	/// test if all elements match names
	bool opEquals(TNAME[] list)
	{
		return names == list;
	}

}
///
unittest {

	writeln("========> testing ", __FILE__);

	import rbf.fieldtype;
	import rbf.field;

	auto c = new NamedItemsContainer!(Field,true)();
	c ~= new Field("FIELD1", "value1", new FieldType("A/N", "string"), 10);
	c ~= new Field("FIELD2", "value2", new FieldType("A/N", "string"), 30);
	c ~= new Field("FIELD2", "value2", new FieldType("A/N", "string"), 30);
	c ~= new Field("FIELD3", "value3", new FieldType("N", "decimal"), 20);
	c ~= new Field("FIELD3", "value3", new FieldType("N", "decimal"), 20);
	c ~= new Field("FIELD3", "value3", new FieldType("N", "decimal"), 20);
	c ~= new Field("FIELD4", "value4", new FieldType("A/N", "string"), 20);

	auto i=1;
	foreach (f; c) {
		f.value = to!string(i++*10);
	}

	// properties
	assert(c.size == 7);
	assert(c.length == 150);
	assert(c.names == ["FIELD1","FIELD2","FIELD2","FIELD3","FIELD3","FIELD3","FIELD4"]);

	// opEquals
	assert(c == ["FIELD1","FIELD2","FIELD2","FIELD3","FIELD3","FIELD3","FIELD4"]);

	// opindex
	assert(c[0] == tuple("FIELD1","value1","A/N",10UL));
	Field f7; assertThrown(f7 = c[7]);
	assert(c["FIELD3"].length == 3);
	assert(c["FIELD3"][1].value!int == 50);
	assert(c[2..4][1] == tuple("FIELD3", "value3", "N", 20UL));

	// get
	assert(c.get("FIELD3") == tuple("FIELD3", "value3", "N", 20UL));

	// dispatch
	//assert(c.FIELD3 == "40");
	//assert(c.FIELD3(1) == "50");

	// arithmetic
	assert(c.sum!int("FIELD3") == 150);
	assert(c.min!int("FIELD3") == 40);
	assert(c.max!int("FIELD3") == 60);

	// in
	assert("FIELD4" in c);
	assert("FIELD10" !in c);

	// misc
	assert(c.count("FIELD3") == 3);

	// range test
	static assert(isBidirectionalRange!(typeof(c[])));
	c[].each!(e => assert(e.name.startsWith("FIELD")));
	auto r = array(c[].take(1));
	assert(r[0].name == "FIELD1");

	// build a new container based on range
	auto a = c[].filter!(e => e.name == "FIELD3");
	auto e = new NamedItemsContainer!(Field,true)(a);
	assert(e.size == 3);

	// remove
	c.remove("FIELD3");
	assert(c == ["FIELD1","FIELD2","FIELD2","FIELD4"]);
	assertThrown(c.remove("FOO"));

	c.remove(["FIELD2","FIELD4"]);
	assert(c == ["FIELD1"]);

	// keepOnly
	c = new NamedItemsContainer!(Field,true)();
	c ~= new Field("FIELD1", "value1", new FieldType("A/N", "string"), 10);
	c ~= new Field("FIELD2", "value2", new FieldType("A/N", "string"), 30);
	c ~= new Field("FIELD2", "value2", new FieldType("A/N", "string"), 30);
	c ~= new Field("FIELD3", "value3", new FieldType("N", "decimal"), 20);
	c ~= new Field("FIELD3", "value3", new FieldType("N", "decimal"), 20);
	c ~= new Field("FIELD3", "value3", new FieldType("N", "decimal"), 20);
	c ~= new Field("FIELD4", "value4", new FieldType("A/N", "string"), 20);
	c.keepOnly(["FIELD2"]);
	assert(c == ["FIELD2","FIELD2"]);

	// remove by index
	c = new NamedItemsContainer!(Field,true)();
	c ~= new Field("FIELD1", "value1", new FieldType("A/N", "string"), 10);
	c ~= new Field("FIELD2", "value2", new FieldType("A/N", "string"), 30);
	c ~= new Field("FIELD2", "value2", new FieldType("A/N", "string"), 30);
	c ~= new Field("FIELD3", "value3", new FieldType("N", "decimal"), 20);
	c ~= new Field("FIELD3", "value3", new FieldType("N", "decimal"), 20);
	c ~= new Field("FIELD3", "value3", new FieldType("N", "decimal"), 20);
	c ~= new Field("FIELD4", "value4", new FieldType("A/N", "string"), 20);
	c.remove("FIELD2",0);
	assert(c == ["FIELD1","FIELD2","FIELD3","FIELD3","FIELD3","FIELD4"]);
	assertThrown(c.remove("FIELD2",1));
	c.remove("FIELD3",2);
	assert(c == ["FIELD1","FIELD2","FIELD3","FIELD3","FIELD4"]);

	// do not accept duplicates
	auto d = new NamedItemsContainer!(Field,false)();
	d ~= new Field("FIELD2", "value2", new FieldType("A/N", "string"), 10);
	d ~= new Field("FIELD1", "value1", new FieldType("A/N", "string"), 30);
	assertThrown(d ~= new Field("FIELD2", "value2", new FieldType("A/N", "string"), 30));
	d ~= new Field("FIELD4", "value4", new FieldType("N", "decimal"), 20);
	d ~= new Field("FIELD3", "value3", new FieldType("A/N", "string"), 20);

	i=1;
	foreach (f; d) {
		f.value = to!string(i++*10);
	}

	// properties
	assert(d.size == 4);
	assert(d.length == 80);
	assert(d.names == ["FIELD2","FIELD1","FIELD4","FIELD3"]);

	// opEquals
	assert(d == ["FIELD2","FIELD1","FIELD4","FIELD3"]);

	// opindex
	assert(d[0] == tuple("FIELD2", "value2", "A/N", 10UL));
	assert(d["FIELD3"] == tuple("FIELD3", "value3", "A/N", 20UL));
	assert(d["FIELD3"].value!int == 40);
	assert(d[1..3][1] == tuple("FIELD4", "value4", "N", 20UL));

	// get
	assert(d.get("FIELD3") == tuple("FIELD3", "value3", "A/N", 20UL));

	// dispatch
	//assert(d.FIELD3 == "40");
	//assert(!__traits(compiles, d.FIELD3(1) == "50"));

	// belong to
	assert("FIELD3" in d);

	// test sorted foreach
	string[] names;
	foreach (f; &d.sorted) {
		names ~= f.name;
	}
	assert(names == ["FIELD1","FIELD2","FIELD3","FIELD4"]);

	// test compilation with different structures
	struct NoName {}
	struct HasNameNoLength { string name; }
	struct HasNameLength { string name; string length; }
	assert(!__traits(compiles, new NamedItemsContainer!(NoName,true)()));
	auto f1 = new NamedItemsContainer!(HasNameNoLength,true)();
	auto f2 = new NamedItemsContainer!(HasNameLength,true)();

}
