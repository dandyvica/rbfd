// D import file generated from 'source/record.d'
module rbf.record;
import std.stdio;
import std.conv;
import std.string;
import std.algorithm;
import std.array;
import std.regex;
import std.range;
import rbf.field;
class Record
{
	private 
	{
		immutable string _name;
		immutable string _description;
		Field[] _field_list;
		Field[][string] _field_map;
		ulong _length;
		string _line;
		public 
		{
			this(in string name, in string description);
			@property string name();
			@property string description();
			@property string line();
			@property void line(string new_line);
			@property ulong length();
			@property void value(string s);
			@property string value();
			@property string[] fieldNames();
			@property string[] fieldValues();
			void autoRename();
			void opOpAssign(string op)(Field field) if (op == "~")
			{
				field.index = _field_list.length;
				field.offset = this.length;
				_field_list ~= field;
				_field_map[field.name] ~= field;
				_length += field.length;
			}
			Field opIndex(size_t i);
			Field[] opIndex(string fieldName);
			Field[]* opBinaryRight(string op)(string fieldName)
			{
				if (op == "in")
				{
					return fieldName in _field_map;
				}
			}
			int opApply(int delegate(ref Field) dg);
			Record dup();
			Field get(string fieldName, ushort index);
			string toTxt();
			string opDispatch(string fieldName)(ushort index)
			{
				enforce(0 <= index && index < _field_map[fieldName].length, "field %s, index %d is out of bounds".format(fieldName, index));
				return this[fieldName][index].value;
			}
			@property string opDispatch(string attrName)()
			{
				return this[attrName][0].value;
			}
			override string toString();
		}
	}
}
import std.exception;
