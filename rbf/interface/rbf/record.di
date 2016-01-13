// D import file generated from 'source\rbf\record.d'
module rbf.record;
pragma (msg, "========> Compiling module ", "rbf.record");
import std.stdio;
import std.conv;
import std.string;
import std.algorithm;
import std.array;
import std.regex;
import std.range;
import std.container.array;
import rbf.field;
import rbf.nameditems;
import rbf.recordfilter;
struct RecordMeta
{
	string name;
	string description;
	bool skip;
	string[][] repeatingPattern;
	Record[] subRecord;
	string ruler;
	ulong sourceLineNumber;
	bool section;
}
class Record : NamedItemsContainer!(Field, true, RecordMeta)
{
	public 
	{
		this(in string name, in string description)
		{
			enforce(name != "", "record name should not be empty!");
			super(name);
			this.meta.name = name;
			this.meta.description = description;
		}
		@property void value(TVALUE s)
		{
			if (s.length < _length)
			{
				s = s.leftJustify(_length);
			}
			else
				if (s.length > _length)
				{
					s = s[0.._length];
				}
			this.each!((f) => f.value = s[f.context.lowerBound..f.context.upperBound]);
		}
		@property string rawValue()
		{
			return fieldRawValues.join("");
		}
		@property string value()
		{
			return fieldValues.join("");
		}
		@property string[] fieldNames()
		{
			mixin(NamedItemsContainer!(Field, true).getMembersData("name"));
		}
		@property string[] fieldAlternateNames()
		{
			mixin(NamedItemsContainer!(Field, true).getMembersData("context.alternateName"));
		}
		auto @property fieldValues()
		{
			mixin(NamedItemsContainer!(Field, true).getMembersData("value"));
		}
		auto @property fieldRawValues()
		{
			mixin(NamedItemsContainer!(Field, true).getMembersData("rawValue"));
		}
		@property string[] fieldDescriptions()
		{
			mixin(NamedItemsContainer!(Field, true).getMembersData("description"));
		}
		@property TVALUE concat(string name)
		{
			auto values = array(this[name].map!((f) => f.value));
			return values.reduce!((a, b) => a ~ b);
		}
		string findNameByIndex(in ulong i)
		{
			foreach (f; this)
			{
				if (f.context.index == i)
					return f.name;
			}
			return "";
		}
		void recalculateIndex()
		{
			auto i = 0;
			this.each!((f) => f.context.index = i++);
		}
		void buildAlternateNames()
		{
			foreach (f; this)
			{
				auto list = this[f.name];
				if (list.length > 1)
				{
					auto i = 1;
					foreach (f1; list)
					{
						f1.context.alternateName = "%s%d".format(f1.name, i++);
					}
				}
			}
		}
		void identifyRepeatedFields()
		{
			string s;
			foreach (f; this)
			{
				auto i = _map[f.name][0].context.index;
				s ~= "<%d>".format(i);
			}
			auto pattern = ctRegex!"((<\\d+>)+?)\\1+";
			auto match = matchAll(s, pattern);
			foreach (m; match)
			{
				auto result = matchAll(m[1], "<(\\d+)>");
				auto a = array(result.map!((r) => findNameByIndex(to!ulong(r[1]))));
				meta.repeatingPattern ~= a;
			}
		}
		void findRepeatedFields(string[] fieldList)
		{
			auto indexOfFirstField = array(this[fieldList[0]].map!((f) => f.context.index));
			immutable l = fieldList.length;
			foreach (i; indexOfFirstField)
			{
				if (i + l > size)
					break;
				auto recName = join(fieldList, ";");
				meta.subRecord ~= new Record(recName, "subRecord");
				auto a = this[i..i + l];
				if (array(this[i..i + l].map!((f) => f.name)) == fieldList)
				{
					meta.subRecord[$ - 1] ~= a;
				}
			}
		}
		void opOpAssign(string op)(Field field) if (op == "~")
		{
			field.context.index = this.size;
			field.context.offset = this.length;
			super.opOpAssign!"~"(field);
			field.context.occurence = this.size(field.name) - 1;
			field.context.lowerBound = field.context.offset;
			field.context.upperBound = field.context.offset + field.length;
		}
		void opOpAssign(string op)(Field[] fieldList) if (op == "~")
		{
			fieldList.each!((f) => super.opOpAssign!"~"(f));
		}
		override string toString()
		{
			auto s = "\x0aname=<%s>, description=<%s>, length=<%u>, skip=<%s>\x0a".format(name, meta.description, length, meta.skip);
			foreach (field; this)
			{
				s ~= field.toString();
				s ~= "\x0a";
			}
			return s;
		}
		bool matchRecordFilter(RecordFilter filter)
		{
			foreach (RecordClause c; filter)
			{
				if (!(c.fieldName in this))
				{
					return false;
				}
				bool condition = false;
				foreach (Field field; this[c.fieldName])
				{
					condition |= field.type.isFieldFilterMatched(field.value, c.operator, c.scalar);
				}
				if (!condition)
					return false;
			}
			return true;
		}
	}
}
import std.exception;
