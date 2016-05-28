module rbf.writers.boxwriter;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;
import std.range;
import std.utf;

import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;

// list of box characters
immutable topLeft       = '\u250C';
immutable bottomLeft    = '\u2514';
immutable topRight      = '\u2510';
immutable bottomRight   = '\u2518';
immutable verticalBar   = '\u2502';
immutable horizontalBar = '\u2500';
immutable topCross      = '\u252C';
immutable bottomCross   = '\u2534';
immutable leftCross     = '\u251C';
immutable rightCross    = '\u2524';
immutable cross         = '\u253C';

// format used to print out string or numerical data

/*********************************************
 * in this case, each record is displayed as an ASCII table
 */
class BoxWriter : Writer {

private:
	string _fmt;
	size_t _lineLength;
    wchar[] _lastFooter;

public:

	this(in string outputFileName)
	{
		super(outputFileName);
	}

	// preparation step beodre printing out records
	override void prepare(Layout layout) {
		// as seperator is known at that time, build formatting string
		_fmt = "%%-*s%s".format(settings.outputConfiguration.fieldSeparator);
	}

	override void write(Record rec)
	{
		// this
        auto lengths = array(rec[].map!(f => f.cellLength1));

		// print new header if new record
		if (_previousRecordName != rec.name) {
            // gracefully end last record
            if (_previousRecordName != "") 
                 _fh.writeln(_lastFooter);

			_fh.writeln();

			// print top line
            _fh.writeln(_boxLine(topLeft, horizontalBar, topCross, topRight, lengths));

			// print names
            _fh.write(verticalBar);
		    rec.each!(f => _fh.writef( "%-*s%c", f.cellLength1, toUTF8(f.name), verticalBar));
            _fh.writeln();

			// print separator
            _fh.writeln(_boxLine(leftCross, horizontalBar, cross, rightCross, lengths));

	    }

		// finally write out values
        _fh.write(verticalBar);
        rec.each!(f => _fh.writef( "%-*s%c", f.cellLength1, f.value, verticalBar));
		_fh.writeln();

		// save record name
		_previousRecordName = rec.name;

        // if any save footer
        _lastFooter = _boxLine(bottomLeft, horizontalBar, bottomCross, bottomRight, lengths);
	}

    override void build(string outputFileName) {}

private:

	// print out each field
	wchar[] _boxLine(wchar begin, wchar middle, wchar joiner, wchar end, size_t[] lengths)
    {
        auto la = array(lengths.map!(l => middle.repeat(l)));
        return begin ~ join(la, joiner) ~ end;
	}

}
///
unittest {

	writeln("========> testing ", __FILE__);

	import rbf.layout;
	import rbf.reader;

	auto layout = new Layout("./test/world_data.xml");
	auto reader = new Reader("./test/world.data", layout);

	auto writer = writerFactory("./test/world_data.txt", OutputFormat.box);
	writer.settings.outputConfiguration.fieldSeparator   = "!";
	writer.settings.outputConfiguration.fieldDescription = true;
	writer.settings.outputConfiguration.lineSeparator    = "$";
	writer.settings.outputConfiguration.useAlternateName = true;

	writer.prepare(layout);

	foreach (rec; reader) { writer.write(rec); }

	writer.close();
}
