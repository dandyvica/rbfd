// D import file generated from 'source\rbf\writers\txtwriter.d'
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
			this(in string outputFileName)
			{
				super(outputFileName);
			}
			override void prepare(Layout layout)
			{
				_fmt = "%%-*s%s".format(outputFeature.fsep);
				size_t rulerLength;
				foreach (rec; layout)
				{
					rulerLength = 0;
					foreach (f; rec)
					{
						f.cellLength1 = outputFeature.useAlternateName ? max(f.length, f.context.alternateName.length) : max(f.length, f.name.length);
						rulerLength += f.cellLength1;
					}
					if (outputFeature.lsep != "")
					{
						rec.meta.ruler = to!string(outputFeature.lsep[0].repeat(rulerLength + rec.size));
					}
				}
			}
			override void build(string outputFileName)
			{
			}
			override void write(Record rec)
			{
				if (_previousRecordName != rec.name)
				{
					_fh.writeln();
					if (outputFeature.useAlternateName)
						rec.each!((f) => _write!"context.alternateName"(f));
					else
						rec.each!((f) => _write!"name"(f));
					if (outputFeature.lsep != "")
					{
						_fh.writeln;
						_fh.writef("%s", rec.meta.ruler);
					}
					_fh.writeln();
				}
				rec.each!((f) => _write!"value"(f));
				_fh.writeln();
				_previousRecordName = rec.name;
			}
			private void _write(string member)(Field f)
			{
				_fh.writef(_fmt, f.cellLength1, mixin("f." ~ member));
			}
		}
	}
}
