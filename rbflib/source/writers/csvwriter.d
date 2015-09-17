module rbf.writers.csvwriter;

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
class CSVWriter : Writer {

	this(in string outputFileName)
	{
		super(outputFileName);
		_fh = File(outputFileName, "w");
	}

	override void write(Record rec)
	{
		_fh.write(join(rec.fieldValues, ";"), "\n");
	}

	override void close() { _fh.close(); }
}
