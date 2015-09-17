module rbf.writers.txtwriter;

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
 * in this case, each record is displayed as an ASCII table
 */
class TXTWriter : Writer {

public:

	this(in string outputFileName)
	{
		super(outputFileName);
		_fh = File(outputFileName, "w");
	}

	override void write(Record rec)
	{
		if (_previousRecordName != rec.name) {
				_fh.writeln();

			rec.each!(
				f => 	_fh.writef("%-*s|", f.cell_length, f.name)
			);

				/*
			foreach (int j, name; rec.fieldNames) {
				// left justifiy with - format
				_fh.writef("%-*s|", rec[j].cell_length, name);
			}*/
			_fh.writeln();
	  }

		rec.each!(
			f => 	_fh.writef("%-*s|", f.cell_length, f.value)
		);

/*
		foreach (int j, value; rec.fieldValues) {
			// left justifiy with - format
			_fh.writef("%-*s|", rec[j].cell_length, value);
		}*/

		_fh.writeln();

		//
		_previousRecordName = rec.name;
	}

	override void close() { _fh.close(); }
}
