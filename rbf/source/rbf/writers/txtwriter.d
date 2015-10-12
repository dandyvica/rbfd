module rbf.writers.txtwriter;
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
 * in this case, each record is displayed as an ASCII table
 */
class TXTWriter : Writer {

public:

	this(in string outputFileName)
	{
		super(outputFileName);
	}

	override void write(Record rec)
	{
		if (_previousRecordName != rec.name) {
				_fh.writeln();

			rec.each!(
				f => 	_fh.writef("%-*s|", f.cellLength, f.name)
			);

			_fh.writeln();
	  }

		rec.each!(
			f => 	_fh.writef("%-*s|", f.cellLength, f.value)
		);

		_fh.writeln();

		//
		_previousRecordName = rec.name;
	}

}
