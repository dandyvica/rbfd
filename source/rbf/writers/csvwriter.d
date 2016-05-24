module rbf.writers.csvwriter;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;

import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;

/*********************************************
 * CSV class
 */
class CSVWriter : Writer 
{

	this(in string outputFileName)
	{
		super(outputFileName);
	}

	override void prepare(Layout layout) {}
    override void build(string outputFileName) {}

    override void write(Record rec)
    {
        // finally write out values
        if (outputFeature.useRawValue) 
            _fh.writeln(join(rec.fieldRawValues, outputFeature.fieldSeparator));
        else
            _fh.writeln(join(rec.fieldValues, outputFeature.fieldSeparator));
	}

}
///
unittest {

	writeln("========> testing ", __FILE__);

	import rbf.reader;
	import rbf.layout;

	auto layout = new Layout("./test/world_data.xml");
	auto reader = new Reader("./test/world.data", layout);

	auto writer = writerFactory("./test/world_data.csv", OutputFormat.csv);
	writer.outputFeature.fieldSeparator = "-";

	foreach (rec; reader) { writer.write(rec); }

}