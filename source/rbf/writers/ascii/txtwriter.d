module rbf.writers.ascii.txtwriter;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.conv;
import std.exception;
import std.algorithm;
import std.range;

import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;

/*********************************************
 * in this case, each record is displayed as an ASCII table
 */
class TXTWriter : Writer 
{

private:
	string _fmt;

public:

	/** 
     * Prepare file name
	 *
	 * Params:
	 * 	outputFileName = text file name
	 *
	 */
	this(in string outputFileName)
	{
		super(outputFileName);
	}

	/** 
     * Prepare the string format used to write out data
	 *
	 * Params:
	 * 	layout = Layout object
	 *
	 */
    override void prepare(Layout layout) 
    {
        // as separator is known at that time, build formatting string
        _fmt = "%%-*s%s".format(settings.outputConfiguration.fieldSeparator);

        // calculate all lengths in advance
        size_t rulerLength;
        foreach (rec; layout)
        {
            rulerLength = 0;

            // length is depending whether we use name or alternateName
            foreach (f; rec) 
            {
                f.cellLength1 = settings.outputConfiguration.useAlternateName ? 
                    max(f.length, f.context.alternateName.length) : max(f.length, f.name.length);

                // ruler length is the sum of all length
                rulerLength += f.cellLength1;
            }

            // set ruler characters
            if (settings.outputConfiguration.lineSeparator != "")
            {
                rec.meta.ruler = to!string(settings.outputConfiguration.lineSeparator[0].repeat(rulerLength+rec.size));
            }
        }
    }

    override void build(string outputFileName) {}

	/** 
     * Write a record in the opened text file
	 *
	 * Params:
	 * 	rec = Record object
	 *
	 */
	override void write(Record rec)
	{
        // print new header if this is a new record
        if (_previousRecordName != rec.name) 
        {
            _fh.writeln();

            // print out names or alternate names depending on chosen option
            if (settings.outputConfiguration.useAlternateName)
                rec.each!(f => _write!"context.alternateName"(f));
            else
                rec.each!(f => _write!"name"(f));

            // print line separator if requested
            if (settings.outputConfiguration.lineSeparator != "") 
            {
                _fh.writeln; 
                _fh.writef("%s", rec.meta.ruler);
            }

            _fh.writeln();
        }

        // finally write out values
        if (settings.outputConfiguration.useRawValue) 
            rec.each!(f => 	_write!"rawValue"(f));
        else
            rec.each!(f => 	_write!"value"(f));
        _fh.writeln();

        // save record name
        _previousRecordName = rec.name;
	}

private:

	/** 
     * Generic writer for any subfield
	 *
	 * Params:
	 * 	member = Field member name
	 *  f = Field object
     *
	 */
	void _write(string member)(Field f) 
    {
		// print out data
	    _fh.writef(_fmt, f.cellLength1, mixin("f." ~ member));
	}

}
///
unittest {

	writeln("========> testing ", __FILE__);

	import rbf.layout;
	import rbf.reader;

	auto layout = new Layout("./test/world_data.xml");
	auto reader = new Reader("./test/world.data", layout);

	auto writer = writerFactory("./test/world_data.txt", OutputFormat.txt);
	writer.settings.outputConfiguration.fieldSeparator = "!";
	writer.settings.outputConfiguration.fieldDescription = true;
	writer.settings.outputConfiguration.lineSeparator = "$";
	writer.settings.outputConfiguration.useAlternateName = true;

	writer.prepare(layout);

	foreach (rec; reader) { writer.write(rec); }

	writer.close();
}
