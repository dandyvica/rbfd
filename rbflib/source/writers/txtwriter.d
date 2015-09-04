module rbf.writers.txtwriter;

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
 * in this case, each record is displayed as an ASCII table
 */
class TXTWriter : Writer {

	this(in string outputFileName)
	{
		super(outputFileName);
		_fh = File(outputFileName, "w");
	}

	override void write(Record rec)
	{
		uint i = 0;
		foreach (name; rec.fieldNames) {
			// left justifiy with - format
			_fh.writef("%-*s|", rec[i++].cell_length, name);
		}
		_fh.writeln();

		i = 0;
		foreach (value; rec.fieldValues) {
			// left justifiy with - format
			_fh.writef("%-*s|", rec[i++].cell_length, value);
		}
		_fh.writeln("\n");

	}

	override void close() { _fh.close(); }
}
