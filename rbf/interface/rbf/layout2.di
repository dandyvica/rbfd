// D import file generated from 'source/rbf/layout2.d'
module rbf.layout2;
pragma (msg, "========> Compiling module ", "rbf.layout2");
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
class Layout2 : NamedItemsContainer!(Record, false)
{
	public 
	{
		this(string xmlFile);
		Field[]* opBinaryRight(string op)(string fieldName)
		{
			static if (op == "in")
			{
				foreach (rec; this)
				{
					auto f = fieldName in rec;
					if (f)
						return f;
				}
				return null;
			}

		}
		override string toString();
		void keepOnly(string[][string] recordMap);
		void removeFromAllRecords(string[] fieldList);
		void validate();
	}
}
