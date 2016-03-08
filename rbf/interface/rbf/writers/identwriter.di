// D import file generated from 'source/rbf/writers/identwriter.d'
module rbf.writers.identwriter;
pragma (msg, "========> Compiling module ", "rbf.writers.identwriter");
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
class IdentWriter : Writer
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
		_fh.writeln(rec.rawValue);
	}
}
