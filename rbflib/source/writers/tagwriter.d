module rbf.writers.tagwriter;

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;

import rbf.field;
import rbf.record;
import rbf.reader;
import rbf.conf;

import rbf.writers.writer;

/*********************************************
 * writer class for writing to various ouput
 * formats
 */
class TAGWriter : Writer {

	this(in string outputFileName)
	{
		super(outputFileName);
		_fh = File(outputFileName, "w");
	}

	override void write(Record rec)
	{
		foreach (field; rec) {
			_fh.write(`%s="%s" `.format(field.name, field.value));
		}
		_fh.writeln();
	}

	override void close() { _fh.close(); }
}
