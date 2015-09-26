module rbf.writers.tagwriter;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;

import rbf.field;
import rbf.record;
import rbf.writers.writer;

/*********************************************
 * writer class for writing tagged records
 * (one record per line)
 */
class TAGWriter : Writer {

	this(in string outputFileName)
	{
		super(outputFileName);
	}

	override void write(Record rec)
	{
		_fh.writef("%s:", rec.name);
		foreach (field; rec) {
			_fh.write(`%s="%s" `.format(field.name, field.value));
		}
		_fh.writeln();
	}

}
