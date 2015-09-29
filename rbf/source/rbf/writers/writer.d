module rbf.writers.writer;
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
import rbf.writers.xlsxwriter;
import rbf.writers.csvwriter;
import rbf.writers.txtwriter;
import rbf.writers.htmlwriter;
import rbf.writers.tagwriter;
import rbf.writers.identwriter;

/*********************************************
 * writer class for writing to various ouput
 * formats
 */
abstract class Writer {
private:

	string _outputFileName; 			// name of the file we want to create
	string _zipperExe;						// name & path of the executable used to create zip

package:

	File _fh; // file handle on output file if any
	string _previousRecordName;		/// sometimes, we need to keep track of the previous record written

public:
	/**
	 * creates a new Writer object for converting record-based files
	 *
	 Params:
	 outputFileName = name of the output file (or database name in case of sqlite3)
	 create = true if file is created during constructor
	 */
	this(in string outputFileName, in bool create = true)
	{
		_outputFileName = outputFileName;
		if (create) _fh = File(_outputFileName, "w");
	}

	// zipper executable
	@property string zipper() { return _zipperExe; }
	@property void zipper(string zipperExe) { _zipperExe = zipperExe; }

	// should be implemented by derived classes
	abstract void write(Record rec);
	//abstract void close();

	void open() {
		_fh = File(_outputFileName, "w");
	}
	void close() {
		_fh.close();
	}

}

/*********************************************
 * factory method for creating object matching
 * desired format
 */
Writer writerFactory(in string output, in string mode, Layout layout)
{
	switch(mode)
	{
		case "html": return new HTMLWriter(output);
		case "csv" : return new CSVWriter(output);
		case "txt" : return new TXTWriter(output);
		case "xlsx": return new XLSXWriter(output, layout);
		case "sql" : return new TXTWriter(output);
		case "tag" : return new TAGWriter(output);
		case "ident" : return new IdentWriter(output);
		default:
			throw new Exception("error: writer unknown mode <%s>".format(mode));
	}
}
///
unittest {

	import rbf.reader;
	import std.regex;

	auto layout = new Layout("./test/world_data.xml");

	auto reader = new Reader("./test/world.data", layout, (line => line[0..4]));
	reader.ignoreRegexPattern = regex("^#");

	auto writer1 = writerFactory("test.html", "html", reader.layout);
	foreach (rec; reader) { writer1.write(rec); }

	auto writer2 = writerFactory("test.txt", "txt", reader.layout);
	foreach (rec; reader) { writer2.write(rec); }

	auto writer3 = writerFactory("test.csv", "csv", reader.layout);
	foreach (rec; reader) { writer3.write(rec); }

	auto writer4 = writerFactory("test.xlsx", "xlsx", reader.layout);
	version(linux) { writer4.zipper = "/usr/bin/zip"; }
	foreach (rec; reader) { writer4.write(rec); }

	writer4.close();
}
