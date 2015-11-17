// D import file generated from 'source/rbf/record.d'
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
}
class Record : NamedItemsContainer!(Field, true, RecordMeta)
{
	public 
	{
		this(in string name, in string description);
		@property void value(valueType s);
		@property string value();
		@property string[] fieldNames();
		@property string[] fieldAlternateNames();
		@property string[] fieldValues();
		@property string[] fieldRawValues();
		@property string[] fieldDescriptions();
		string findByIndex(ulong i);
		void recalculateIndex();
		void buildAlternateNames();
		void identifyRepeatedFields();
		void findRepeatedFields(string[] fieldList);
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
		override string toString();
		bool matchRecordFilter(RecordFilter filter);
	}
}
import std.exception;
