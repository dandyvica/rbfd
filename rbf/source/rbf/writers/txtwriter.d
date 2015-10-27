module rbf.writers.txtwriter;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;
import std.range;

import rbf.field;
import rbf.record;
import rbf.writers.writer;

/*********************************************
 * in this case, each record is displayed as an ASCII table
 */
class TXTWriter : Writer {

private:
	string _fmt;
	size_t _lineLength;

public:

	this(in string outputFileName)
	{
		super(outputFileName);
	}

	override void prepare() {
		_fmt = "%%-*s%s".format(outputFeature.fsep);
	}

	override void write(Record rec)
	{
		//
		_lineLength = rec.size * outputFeature.fsep.length;

		// build formatting string from field definitions

		// use to know which cell length to use
		// auto cellLength = (outputFeature.fielddesc) ?
		// 			(Field f) => f.cellLength2 : (Field f) => f.cellLength1;

		// print new header if new record
		if (_previousRecordName != rec.name) {
			_fh.writeln(); rec.each!(f => _write!"name"(f, true));

			// print field descriptions if requested
			if (outputFeature.fielddesc) {
				_fh.writeln(); rec.each!(f => _write!"description"(f));
			}

			// print line separator if requested
			if (outputFeature.lsep != "")	_fh.writef("\n%s", outputFeature.lsep[0].repeat(_lineLength));

			_fh.writeln();
	  }

		// finally write out values
		rec.each!(f => 	_write!"value"(f));
		_fh.writeln();

		// save record name
		_previousRecordName = rec.name;
	}

private:

	// print out each field
	void _write(string member)(Field f, bool calculateLineLength = false) {

		// calculate cell length depending on output seperator
		auto cellLength = (outputFeature.fielddesc) ? f.cellLength2 : f.cellLength1;

		// calculate line seperator length if any
		if (calculateLineLength) _lineLength += cellLength;

		// print out data
	  _fh.writef(_fmt, cellLength, mixin("f." ~ member));

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
	writer.outputFeature.lsep = "$";
	writer.prepare;

	foreach (rec; reader) { writer.write(rec); }

	writer.close();
}
