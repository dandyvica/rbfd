// D import file generated from 'source/rbf/record.d'
module rbf.record;
import std.stdio;
import std.conv;
import std.string;
import std.algorithm;
import std.array;
import std.regex;
import std.range;
import std.container.array;
import rbf.field;
import rbf.recordfilter;
immutable preAllocSize = 30;
class Record
{
	private 
	{
		string _name;
		string _description;
		Field[] _fieldList;
		Field[][string] _fieldMap;
		ulong _length;
		bool _keep = true;
		public 
		{
			this(in string name, in string description);
			@property string name();
			@property string description();
			@property ulong length();
			@property ulong size();
			@property bool keep();
			@property void keep(bool keep);
			@property void value(string s);
			@property string value();
			@property string[] fieldNames();
			@property string[] fieldValues();
			@property string[] fieldRawValues();
			void autoRename();
			void opOpAssign(string op)(Field field) if (op == "~")
			{
				field.index = _fieldList.length;
				field.offset = this.length;
				_fieldList ~= field;
				_fieldMap[field.name] ~= field;
				_length += field.length;
				field.lowerBound = field.offset;
				field.upperBound = field.offset + field.length;
			}
			Field opIndex(size_t i);
			Field[] opIndex(string fieldName);
			Field[]* opBinaryRight(string op)(string fieldName)
			{
				static if (op == "in")
				{
					return fieldName in _fieldMap;
				}

			}
			bool empty();
			ref Field front();
			void popFront();
			int opApply(int delegate(ref Field) dg);
			Record dup();
			void remove(string fieldName);
			void lazyRemove(string fieldName);
			void keepOnly(string[] listOfFieldNamesToKeep);
			Field get(string fieldName, ushort index = 0);
			string opDispatch(string fieldName)(ushort index)
			{
				enforce(0 <= index && index < _fieldMap[fieldName].length, "field %s, index %d is out of bounds".format(fieldName, index));
				return this[fieldName][index].value;
			}
			@property string opDispatch(string attrName)()
			{
				return this[attrName][0].value;
			}
			override string toString();
			bool matchRecordFilter(RecordFilter filter);
		}
	}
}
import std.exception;
