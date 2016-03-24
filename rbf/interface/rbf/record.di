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
import rbf.errormsg;
import rbf.field;
import rbf.nameditems;
import rbf.recordfilter;
import rbf.builders.xmlcore;
struct RecordMeta
{
	string name;
	string description;
	bool skipRecord;
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
		this(in string name, in string description);
		this(string[string] attr);
		@property void value(TVALUE s);
		@property string rawValue();
		@property string value();
		@property string[] fieldNames();
		@property string[] fieldAlternateNames();
		auto @property fieldValues()
		{
			mixin(NamedItemsContainer!(Field, true).getMembersData("value"));
		}
		auto @property fieldRawValues()
		{
			mixin(NamedItemsContainer!(Field, true).getMembersData("rawValue"));
		}
		@property string[] fieldDescriptions();
		@property TVALUE concat(string name);
		string findNameByIndex(in ulong i);
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
		string asXML();
	}
}
import std.exception;
