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
				size_t cellLength1 = f.cellLength1, cellLength2 = f.cellLength2;
				auto fieldMember = mixin("f." ~ member);
				static if (member == "name")
				{
					if (outputFeature.useAlternateName)
					{
						fieldMember = "%s(%d)".format(f.name, f.context.occurence + 1);
						cellLength1 = max(f.cellLength1, fieldMember.length);
						cellLength2 = max(f.cellLength2, fieldMember.length);
					}
				}

				auto cellLength = outputFeature.fielddesc ? cellLength2 : cellLength1;
				if (calculateLineLength)
					_lineLength += cellLength;
				_fh.writef(_fmt, cellLength, fieldMember);
			}
		}
	}
}
