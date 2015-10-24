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
		// use to know which cell length to use
		auto cellLength = (outputFeature.fielddesc) ?
					(Field f) => f.cellLength2 : (Field f) => f.cellLength1;

		// print new header if new record
		if (_previousRecordName != rec.name) {
			_fh.writeln();
			rec.each!(f => 	_fh.writef("%-*s%s", cellLength(f), f.name, outputFeature.fsep));

			// print field descriptions if requested
			if (outputFeature.fielddesc) {
			_fh.writeln();
				rec.each!(f => 	_fh.writef("%-*s%s", cellLength(f), f.description, outputFeature.fsep));
			}

			// print line break if requested
			if (outputFeature.lsep != "") {
				// compute line length for separation
				size_t lineLength;
				foreach (f; rec) {
					lineLength += cellLength(f);
				}
				lineLength += rec.size * outputFeature.fsep.length;

				// print out line separator
				_fh.writeln();
				foreach (i; 0..lineLength) { _fh.writef("%c", outputFeature.lsep[0]); }
			}

			_fh.writeln();
	  }

		// finally write out values
		rec.each!(f => 	_fh.writef("%-*s%s", cellLength(f), f.value, outputFeature.fsep));
		_fh.writeln();

		// save record name
		_previousRecordName = rec.name;
	}

}
///
unittest {

	writeln("========> testing ", __FILE__);

	import rbf.layout;
	import rbf.reader;

	auto layout = new Layout("./test/world_data.xml");
	auto reader = new Reader("./test/world.data", layout);

	auto writer = writerFactory("./test/world_data.txt", "txt", layout);
	writer.outputFeature.fsep = "!";
	writer.outputFeature.fielddesc = true;
	writer.outputFeature.lsep = "-";

	foreach (rec; reader) { writer.write(rec); }

	writer.close();
}
