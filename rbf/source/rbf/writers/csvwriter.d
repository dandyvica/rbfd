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
import rbf.writers.writer;

/*********************************************
 * writer class for writing to various ouput
 * formats
 */
class CSVWriter : Writer {

	this(in string outputFileName)
	{
		super(outputFileName);
	}

	override void write(Record rec)
	{
		_fh.write(join(rec.fieldValues, outputFeature.fsep), "\n");
	}

}
///
unittest {

	writeln("========> testing ", __FILE__);

	import rbf.reader;
	import rbf.layout;

	auto layout = new Layout("./test/world_data.xml");
	auto reader = new Reader("./test/world.data", layout);

	auto writer = writerFactory("world_data.csv", "csv", layout);
	writer.outputFeature.fsep = "-";

	foreach (rec; reader) { writer.write(rec); }

}
