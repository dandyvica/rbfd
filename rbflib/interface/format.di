// D import file generated from 'source/format.d'
module rbf.format;
import std.stdio;
import std.file;
import std.string;
import std.xml;
import std.conv;
import std.exception;
import rbf.field;
import rbf.record;
class Format
{
	private 
	{
		Record[string] _records;
		public 
		{
			this(string xmlFile);
			@property Record[string] records();
			ref Record opIndex(string recName);
		}
	}
}
