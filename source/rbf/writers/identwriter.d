module rbf.writers.identwriter;
pragma(msg, "========> Compiling module ", __MODULE__);

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

/*********************************************
 * Class for identity writer 
 */
class IdentWriter : Writer 
{

	this(in string outputFileName)
	{
		super(outputFileName);
	}

	override void prepare(Layout layout) {}
    override void build(string outputFileName) {}

    // identity is just printing out the same values than read
	override void write(Record rec)
	{
		_fh.writeln(rec.rawValue);
	}

}
