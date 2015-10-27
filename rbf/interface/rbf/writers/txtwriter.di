// D import file generated from 'source/rbf/writers/txtwriter.d'
module rbf.writers.txtwriter;
pragma (msg, "========> Compiling module ", "rbf.writers.txtwriter");
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;
import std.range;
import rbf.field;
import rbf.record;
import rbf.writers.writer;
class TXTWriter : Writer
{
	private 
	{
		string _fmt;
		size_t _lineLength;
		public 
		{
			this(in string outputFileName);
			override void prepare();
			override void write(Record rec);
			private void _write(string member)(Field f, bool calculateLineLength = false)
			{
				auto cellLength = outputFeature.fielddesc ? f.cellLength2 : f.cellLength1;
				if (calculateLineLength)
					_lineLength += cellLength;
				_fh.writef(_fmt, cellLength, mixin("f." ~ member));
			}
		}
	}
}
