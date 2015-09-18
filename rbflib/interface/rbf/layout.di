// D import file generated from 'source/layout.d'
module rbf.layout;
import std.stdio;
import std.file;
import std.string;
import std.xml;
import std.conv;
import std.exception;
import std.algorithm;
import rbf.field;
import rbf.record;
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
			int opApply(int delegate(ref Record) dg);
			override string toString();
			void prunePerRecord(string[][string] recordMap);
			void pruneAll(string[] fieldList);
			void validate();
		}
	}
}
