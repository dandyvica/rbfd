module rbf.writers.identwriter;

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
 * writer class for writing to various ouput
 * formats
 */
class IdentWriter : Writer {

	this(in string outputFileName)
	{
		super(outputFileName);
	}

	override void write(Record rec)
	{
		_fh.writeln(rec.value);
	}

}
