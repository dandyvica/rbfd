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

	// preparation step beodre printing out records
	override void prepare() {
		// as seperator is known at that time, build formatting string
		_fmt = "%%-*s%s".format(outputFeature.fsep);
	}

	override void write(Record rec)
	{
		// this
		_lineLength = rec.size * outputFeature.fsep.length;

		// print new header if new record
		if (_previousRecordName != rec.name) {
			_fh.writeln(); rec.each!(f => _write!"name"(f, true));

			// print field descriptions if requested
			if (outputFeature.fielddesc) {
				_fh.writeln(); rec.each!(f => _write!"description"(f));
			}

			// print line separator if requested
			if (outputFeature.lsep != "")
				_fh.writef("\n%s", outputFeature.lsep[0].repeat(_lineLength));

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
		// in case of field name followed by its occurence within a record,
		// we need to recalculate all cell lengths
		size_t cellLength1 = f.cellLength1, cellLength2 = f.cellLength2;

		// this is the field member to print
		auto fieldMember = mixin("f." ~ member);

		// build new field name if any
		static if (member == "name") {
			if (outputFeature.useAlternateName) {
					fieldMember = "%s(%d)".format(f.name, f.context.occurence+1);
					cellLength1 = max(f.cellLength1, fieldMember.length);
					cellLength2 = max(f.cellLength2, fieldMember.length);
			}
		}

		// calculate cell length depending on output seperator
		auto cellLength = (outputFeature.fielddesc) ? cellLength2 : cellLength1;

		// calculate line seperator length if any
		if (calculateLineLength) _lineLength += cellLength;

		// print out data
	  _fh.writef(_fmt, cellLength, fieldMember);

	}

	// size_t _calculateLength(Field f) {
	// 	size_t cellLength1 = f.cellLength1, cellLength2 = f.cellLength2;
	//
	//
	// }


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
