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
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.nameditems;
version (unittest)
{
	immutable test_file = "./test/world_data.xml";
	immutable test_file_fieldtype = "./test/world_data_with_types.xml";
}
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
	Regex!char ignoreRecord;
}
class Layout : NamedItemsContainer!(Record, false, LayoutMeta)
{
	private 
	{
		FieldType[string] ftype;
		public 
		{
			this(string xmlFile);
			override string toString();
			void keepOnly(string[][string] recordMap);
			void removeFromAllRecords(string[] fieldList);
			void validate();
			bool isFieldIn(string fieldName);
		}
	}
}
