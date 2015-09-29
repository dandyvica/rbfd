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
import rbf.field;
import rbf.record;
import rbf.nameditems;
version (unittest)
{
	immutable test_file = "./test/world_data.xml";
}
class Layout : NamedItemsContainer!(Record, false)
{
	public 
	{
		this(string xmlFile);
		override string toString();
		void keepOnly(string[][string] recordMap);
		void removeFromAllRecords(string[] fieldList);
		void validate();
	}
}
