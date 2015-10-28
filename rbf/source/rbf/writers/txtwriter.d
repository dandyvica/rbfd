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

// format used to print out string or numerical data

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

	// preparation step beodre printing out records
	override void prepare() {
		// as seperator is known at that time, build formatting string
		_fmt = "%%-*s%s".format(outputFeature.fsep);
	}

	override void write(Record rec)
	{
		// this
		_lineLength = rec.size * outputFeature.fsep.length;

		// build alternate names if any
		if (outputFeature.useAlternateName) {
			foreach (f; rec) {
				if (rec.size(f.name) > 1) {
					// change names only for >1 occurences
					f.context.alternateName =
							outputFeature.alternateNameFmt.format(f.name, f.context.occurence+1);

					// recalculate cell lengths
					f.cellLength1 = max(f.cellLength1, f.context.alternateName.length);
					f.cellLength2 = max(f.cellLength2, f.context.alternateName.length);
				}
				else
					f.context.alternateName = f.name;
			}
		}

		// now we can write out records

		// print new header if new record
		if (_previousRecordName != rec.name) {
			_fh.writeln();

			// print out names or alternate names
			if (outputFeature.useAlternateName)
				rec.each!(f => _write!"context.alternateName"(f, true));
			else
				rec.each!(f => _write!"name"(f, true));

			// print field descriptions if requested
			if (outputFeature.fielddesc) {
				_fh.writeln(); rec.each!(f => _write!"description"(f));
			}

			// print line separator if requested
			if (outputFeature.lsep != "") {
				// print out line separator
				_fh.writef("\n%s", outputFeature.lsep[0].repeat(_calculateLineLength(rec)));
			}

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

	size_t _calculateLineLength(Record rec) {
		auto lineLength = rec.size * outputFeature.fsep.length;
		foreach (f; rec) {
			auto cellLength = (outputFeature.fielddesc) ? f.cellLength2 : f.cellLength1;
			lineLength += cellLength;
		}
		return lineLength;
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
	writer.outputFeature.useAlternateName = true;

	writer.prepare;

	foreach (rec; reader) { writer.write(rec); }

	writer.close();
}
