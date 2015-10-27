module rbf.writers.tagwriter;
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
 * writer class for writing tagged records
 * (one record per line)
 */
class TAGWriter : Writer {

	this(in string outputFileName)
	{
		super(outputFileName);
	}

	override void prepare() {}

	override void write(Record rec)
	{
		_fh.writef("%s:", rec.name);
		foreach (field; rec) {
			_fh.writef(`%s="%s" `,field.name, field.value);
		}
		_fh.writeln();
	}

}
///
unittest {

	writeln("========> testing ", __FILE__);

	import rbf.reader;
	import rbf.layout;

	auto layout = new Layout("./test/world_data.xml");
	auto reader = new Reader("./test/world.data", layout);

	auto writer = writerFactory("./test/world_data.tag", "tag", layout);
	writer.outputFeature.fsep = " ";

	foreach (rec; reader) { writer.write(rec); }

}
