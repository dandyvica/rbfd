// D import file generated from 'source/rbf/writers/txtwriter.d'
module rbf.writers.txtwriter;
pragma (msg, "========> Compiling module ", "rbf.writers.txtwriter");
import std.stdio;
import std.file;
import std.string;
import std.conv;
import std.exception;
import std.algorithm;
import std.range;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;
class TXTWriter : Writer
{
	private 
	{
		string _fmt;
		public 
		{
			this(in string outputFileName);
			override void prepare(Layout layout);
			override void build(string outputFileName);
			override void write(Record rec);
			private void _write(string member)(Field f)
			{
				_fh.writef(_fmt, f.cellLength1, mixin("f." ~ member));
			}
		}
	}
}
