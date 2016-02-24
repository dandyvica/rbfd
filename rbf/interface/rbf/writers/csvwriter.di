// D import file generated from 'source\rbf\writers\csvwriter.d'
module rbf.writers.csvwriter;
pragma (msg, "========> Compiling module ", "rbf.writers.csvwriter");
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;
class CSVWriter : Writer
{
	this(in string outputFileName)
	{
		super(outputFileName);
	}
	override void prepare(Layout layout)
	{
	}
	override void build(string outputFileName)
	{
	}
	override void write(Record rec)
	{
		_fh.writeln(join(rec.fieldValues, outputFeature.fieldSeparator));
	}
}
