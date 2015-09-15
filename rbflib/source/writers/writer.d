module rbf.writers.writer;

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;

import rbf.field;
import rbf.record;
import rbf.reader;
import rbf.conf;
import rbf.layout;

import rbf.writers.xlsxwriter;
import rbf.writers.csvwriter;
import rbf.writers.txtwriter;
import rbf.writers.htmlwriter;
import rbf.writers.tagwriter;

/*********************************************
 * writer class for writing to various ouput
 * formats
 */
abstract class Writer {
private:

	string _outputFileName; // name of the file we want to create

package:

	File _fh; // file handle on output file if any

public:
	/**
	 * creates a new Writer object for converting record-based files
	 *
	 * Params:
	 *  outputFileName = name of the output file (or database name in case of sqlite3)
	 */
	this(in string outputFileName)
	{
		_outputFileName = outputFileName;
	}

	// should be implemented by derived classes
	abstract void write(Record rec);
	abstract void close();

}

/*********************************************
 * factory method for creating object matching
 * desired format
 */
Writer writer(in string output, in string mode, Layout layout)
{
	switch(mode)
	{
		case "html": return new HTMLWriter(output);
		case "csv" : return new CSVWriter(output);
		case "txt" : return new TXTWriter(output);
		case "xlsx": return new XLSXWriter(output, layout);
		case "sql" : return new TXTWriter(output);
		case "tag" : return new TAGWriter(output);
		default:
			throw new Exception("writer unknown mode <%s>".format(mode));
	}
}




unittest {

	writefln("-------------------------------------------------------------");
	writeln(__FILE__);
	writefln("-------------------------------------------------------------");

	auto reader = new Reader("../test/world.data", "../test/world_data.xml", (line => line[0..4]));
	reader.ignore_pattern = "^#";


	auto writer1 = writer("test.html", "html", reader.layout);
	foreach (rec; reader) { writer1.write(rec); }

	auto writer2 = writer("test.txt", "txt", reader.layout);
	foreach (rec; reader) { writer2.write(rec); }

	auto writer3 = writer("test.csv", "csv", reader.layout);
	foreach (rec; reader) { writer3.write(rec); }

	auto writer4 = writer("test.xlsx", "xlsx", reader.layout);
	foreach (rec; reader) { writer4.write(rec); }

	writer4.close();
}
