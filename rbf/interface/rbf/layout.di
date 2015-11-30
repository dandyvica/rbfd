// D import file generated from 'source/rbf/layout.d'
module rbf.layout;
pragma (msg, "========> Compiling module ", "rbf.layout");
import std.stdio;
import std.file;
import std.string;
import std.xml;
import std.conv;
import std.exception;
import std.algorithm;
import std.regex;
import std.array;
import std.path;
import rbf.errormsg;
import rbf.log;
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.nameditems;
version (unittest)
{
	immutable test_file = "./test/world_data.xml";
}
alias MapperFunc = string delegate(TVALUE);
template LayoutCore()
{
	string name;
	string description;
	string file;
}
struct LayoutMeta
{
	mixin LayoutCore!();
	ulong length;
	string layoutVersion;
	string ignoreLinePattern;
	string[] skipField;
	MapperFunc mapper;
	string mapperDefinition;
}
class Layout : NamedItemsContainer!(Record, false, LayoutMeta)
{
	private 
	{
		void _extractMapper(string mapper);
		public 
		{
			FieldType[string] ftype;
			this(string xmlFile);
			override string toString();
			void keepOnly(string[][string] recordMap);
			void keepOnly(in string list, in string separator);
			void removeFromAllRecords(string[] fieldList);
			void validate();
			bool isFieldInLayout(string fieldName);
		}
	}
}
