// D import file generated from 'source/rbf/writers/tagwriter.d'
module rbf.writers.tagwriter;
pragma (msg, "========> Compiling module ", "rbf.writers.tagwriter");
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;
import rbf.field;
import rbf.record;
import rbf.writers.writer;
class TAGWriter : Writer
{
	this(in string outputFileName)
	{
		super(outputFileName);
	}
	override void prepare()
	{
	}
	override void write(Record rec)
	{
		_fh.writef("%s:", rec.name);
		foreach (field; rec)
		{
			_fh.writef("%s=\"%s\" ", field.name, field.value);
		}
		_fh.writeln();
	}
}
