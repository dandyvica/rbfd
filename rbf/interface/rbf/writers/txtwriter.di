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
			this(in string outputFileName)
			{
				super(outputFileName);
			}
			override void prepare()
			{
				_fmt = "%%-*s%s".format(outputFeature.fsep);
			}
			override void write(Record rec)
			{
				_lineLength = rec.size * outputFeature.fsep.length;
				if (outputFeature.useAlternateName)
				{
					foreach (f; rec)
					{
						if (rec.size(f.name) > 1)
						{
							f.context.alternateName = outputFeature.alternateNameFmt.format(f.name, f.context.occurence + 1);
							f.cellLength1 = max(f.cellLength1, f.context.alternateName.length);
							f.cellLength2 = max(f.cellLength2, f.context.alternateName.length);
						}
						else
							f.context.alternateName = f.name;
					}
				}
				if (_previousRecordName != rec.name)
				{
					_fh.writeln();
					if (outputFeature.useAlternateName)
						rec.each!((f) => _write!"context.alternateName"(f, true));
					else
						rec.each!((f) => _write!"name"(f, true));
					if (outputFeature.fielddesc)
					{
						_fh.writeln();
						rec.each!((f) => _write!"description"(f));
					}
					if (outputFeature.lsep != "")
					{
						_fh.writef("\x0a%s", outputFeature.lsep[0].repeat(_calculateLineLength(rec)));
					}
					_fh.writeln();
				}
				rec.each!((f) => _write!"value"(f));
				_fh.writeln();
				_previousRecordName = rec.name;
			}
			private 
			{
				void _write(string member)(Field f, bool calculateLineLength = false)
				{
					auto cellLength = outputFeature.fielddesc ? f.cellLength2 : f.cellLength1;
					if (calculateLineLength)
						_lineLength += cellLength;
					_fh.writef(_fmt, cellLength, mixin("f." ~ member));
				}
				size_t _calculateLineLength(Record rec)
				{
					auto lineLength = rec.size * outputFeature.fsep.length;
					foreach (f; rec)
					{
						auto cellLength = outputFeature.fielddesc ? f.cellLength2 : f.cellLength1;
						lineLength += cellLength;
					}
					return lineLength;
				}
			}
		}
	}
}
