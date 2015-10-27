// D import file generated from 'source/rbf/nameditems.d'
module rbf.nameditems;
pragma (msg, "========> Compiling module ", "rbf.nameditems");
import std.stdio;
import std.container.array;
import std.conv;
import std.algorithm;
import std.string;
import std.process;
import std.range;
import std.typecons;
import std.exception;
import rbf.errormsg;
immutable uint PRE_ALLOC_SIZE = 30;
class NamedItemsContainer(T, bool allowDuplicates, Meta...)
{
	private 
	{
		string _containerName;
		protected 
		{
			static if (!__traits(hasMember, T, "name"))
			{
				pragma (msg, "error: %s class has no <%s> member".format(T.stringof, "name"));
			}
			else
			{
				alias TNAME = typeof(T.name);
			}
			static if (__traits(hasMember, T, "length"))
			{
				alias TLENGTH = typeof(T.length);
				TLENGTH _length;
			}
			alias TLIST = T[];
			alias TMAP = T[][TNAME];
			static if (allowDuplicates)
			{
				alias TRETURN = TLIST;
				ref TRETURN _contextMap(T[][TNAME] map, TNAME name)
				{
					return map[name];
				}
			}
			else
			{
				alias TRETURN = T;
				ref TRETURN _contextMap(T[][TNAME] map, TNAME name)
				{
					return map[name][0];
				}
			}
			TLIST _list;
			TMAP _map;
			public 
			{
				static if (Meta.length > 0)
				{
					Meta[0] meta;
				}
				struct Range
				{
					private TLIST items;
					ulong head = 0;
					ulong tail = 0;
					this(TLIST list)
					{
						items = list;
						head = 0;
						tail = list.length - 1;
					}
					const @property bool empty()
					{
						return items.length == head;
					}
					@property ref T front()
					{
						return items[head];
					}
					@property ref T back()
					{
						return items[tail];
					}
					@property Range save()
					{
						return this;
					}
					void popBack()
					{
						tail--;
					}
					void popFront()
					{
						head++;
					}
					T opIndex(size_t i)
					{
						return items[i];
					}
				}
				this(string name = "")
				{
					_containerName = name;
					_list.reserve(PRE_ALLOC_SIZE);
				}
				this(Range)(Range r)
				{
					this();
					foreach (e; r)
					{
						this ~= e;
					}
				}
				@property string name()
				{
					return _containerName;
				}
				@property ulong size()
				{
					return _list.length;
				}
				@property ulong size(string name)
				{
					return _map[name].length;
				}
				static if (__traits(hasMember, T, "length"))
				{
					@property TLENGTH length()
					{
						return _length;
					}
				}
				static string getMembersData(string memberName)
				{
					return "return array(_list.map!(e => e." ~ memberName ~ "));";
				}
				TNAME[] names()
				{
					mixin(getMembersData("name"));
				}
				void opOpAssign(string op)(T element) if (op == "~")
				{
					static if (!allowDuplicates)
					{
						enforce(!(element.name in _map), "error: element name %s already in container".format(element.name));
					}

					_list ~= element;
					_map[element.name] ~= element;
					static if (__traits(hasMember, T, "length"))
					{
						_length += element.length;
					}

				}
				T opIndex(size_t i)
				{
					enforce(0 <= i && i < _list.length, "error: index %d is out of bounds for _list[]".format(i));
					return _list[i];
				}
				ref TRETURN opIndex(TNAME name)
				{
					enforce(name in this, "error: element %s is not found in container".format(name));
					return _contextMap(_map, name);
				}
				T[] opSlice(size_t i, size_t j)
				{
					return _list[i..j];
				}
				Range opSlice()
				{
					return Range(_list);
				}
				T get(TNAME name, ushort index = 0)
				{
					enforce(name in this, "error: element %s not found in container".format(name));
					enforce(0 <= index && index < _map[name].length, "element %s, index %d is out of bounds".format(name, index));
					static if (!allowDuplicates)
					{
						enforce(index == 0, "error: cannot call get method with index %d without allowing duplicated".format(index));
					}

					return _map[name][index];
				}
				void remove(TNAME name)
				{
					enforce(name in this, MSG001.format(name, this.name));
					_list = _list.remove!((f) => f.name == name);
					_map.remove(name);
				}
				void remove(TNAME name, size_t index)
				{
					enforce(name in this, "error: element %s not found in container".format(name));
					enforce(0 <= index && index < _map[name].length, "element %s, index %d is out of bounds".format(name, index));
					static if (!allowDuplicates)
					{
						enforce(index == 0, "error: cannot call get method with index %d without allowing duplicated".format(index));
					}

					size_t i, j;
					foreach (e; this)
					{
						if (e.name == name && j++ == index)
							break;
						i++;
					}
					_list = _list.remove(i);
					_map[name] = _map[name].remove(index);
				}
				void remove(TNAME[] name)
				{
					name.each!((e) => this.remove(e));
				}
				void keepOnly(TNAME[] name)
				{
					name.each!((e) => enforce(e in this, MSG001.format(e, this.name)));
					_list = array(_list.filter!((e) => name.canFind(e.name)));
					auto keys = _map.keys.filter!((e) => !name.canFind(e));
					keys.each!((e) => _map.remove(e));
				}
				U sum(U)(TNAME name)
				{
					return _list.filter!((e) => e.name == name).map!((e) => to!U(e.value)).sum();
				}
				U max(U)(TNAME name)
				{
					auto values = _list.filter!((e) => e.name == name).map!((e) => to!U(e.value));
					return values.reduce!(std.algorithm.comparison.max);
				}
				U min(U)(TNAME name)
				{
					auto values = _list.filter!((e) => e.name == name).map!((e) => to!U(e.value));
					return values.reduce!(std.algorithm.comparison.min);
				}
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
				TLIST* opBinaryRight(string op)(TNAME name) if (op == "in")
				{
					return name in _map;
				}
				auto count(TNAME name)
				{
					enforce(name in this, MSG001.format(name, this.name));
					return _map[name].length;
				}
				bool opEquals(TNAME[] list)
				{
					return names == list;
				}
			}
		}
	}
}
