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
version (unittest)
{
	immutable test_file = "./test/world_data.xml";
}
class Layout
{
	private 
	{
		Record[string] _records;
		string _description;
		ulong _length;
		public 
		{
			this(string xmlFile);
			@property Record[string] records();
			@property string description();
			@property ulong length();
			ref Record opIndex(string recName);
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
			int opApply(int delegate(ref Record) dg);
			override string toString();
			void keepOnly(string[][string] recordMap);
			void removeFromAllRecords(string[] fieldList);
			void validate();
		}
	}
}
