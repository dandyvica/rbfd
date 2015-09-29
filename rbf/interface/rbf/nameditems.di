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
immutable uint PRE_ALLOC_SIZE = 30;
class NamedItemsContainer(T, bool allowDuplicates)
{
	protected 
	{
		alias TNAME = typeof(T.name);
		alias TVALUE = typeof(T.value);
		alias TLENGTH = typeof(T.length);
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
		TLENGTH _length;
		string _name;
		string _description;
		public 
		{
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
			this(ushort preAllocSize = PRE_ALLOC_SIZE)
			{
				_list.reserve(preAllocSize);
			}
			this(Range)(Range r)
			{
				this();
				foreach (e; r)
				{
					this ~= e;
				}
			}
			@property ulong size()
			{
				return _list.length;
			}
			@property ulong length()
			{
				return _length;
			}
			@property string name()
			{
				return _name;
			}
			@property void name(string name)
			{
				_name = name;
			}
			@property string description()
			{
				return _description;
			}
			@property void description(string description)
			{
				_description = description;
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
				_list ~= element;
				static if (!allowDuplicates)
				{
					assert(!(element.name in _map), "error: element name %s already in container".format(element.name));
				}

				_map[element.name] ~= element;
				_length += element.length;
			}
			T opIndex(size_t i)
			{
				assert(0 <= i && i < _list.length, "index %d is out of bounds for _list[]".format(i));
				return _list[i];
			}
			ref TRETURN opIndex(TNAME name)
			{
				assert(name in this, "element %s is not found in container".format(name));
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
				assert(name in this, "element %s is not found in record %s".format(name));
				assert(0 <= index && index < _map[name].length, "element %s, index %d is out of bounds".format(name, index));
				static if (!allowDuplicates)
				{
					assert(index == 0, "error: cannot call get method with index %d without allowing duplcated");
				}

				return _map[name][index];
			}
			@property TVALUE opDispatch(TNAME name)()
			{
				return _map[name][0].value;
			}
			TVALUE opDispatch(TNAME name)(ushort index) if (allowDuplicates)
			{
				return _map[name][index].value;
			}
			void remove(TNAME name)
			{
				_list = _list.remove!((f) => f.name == name);
				_map.remove(name);
			}
			void remove(TNAME[] name)
			{
				name.each!((e) => this.remove(e));
			}
			void keepOnly(TNAME[] name)
			{
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
				return _list.count!"a.name == b"(name);
			}
			bool opEquals(TNAME[] list)
			{
				return names == list;
			}
		}
	}
}
