module rbf.writer;

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;

import rbf.field;
import rbf.record;
import rbf.reader;

import rbf.xlsxwriter;

//import util.common;
/*********************************************
 * writer class for writing to various ouput
 * formats
 */
abstract class Writer {
private:

	File _fh; // file handle on output file if any
	string _outputFileName; // name of the file we want to create

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

	abstract void write(Record rec);

}

/*********************************************
 * each record is displayed as an HTML table
 */
class HTMLWriter : Writer {

	this(in string outputFileName)
	{
		super(outputFileName);
		_fh = File(outputFileName, "w");
		_fh.write("<html><head><link href=\"../css/rbf.css\" rel=\"stylesheet\" type=\"text/css\"></head><body>\n");
	}

	override void write(Record rec)
	{
		string names="", values="";

		_fh.write("<table>");
		foreach (Field f; rec)
		{
			names ~= "<tr>" ~ f.name ~ "</tr>";
			values ~= "<tr>" ~ f.value ~ "</tr>";
		}
		_fh.write(names, "\n", values);
		_fh.write("</table>");
	}

	~this() { _fh.close(); }
}

/*********************************************
 * writer class for writing to various ouput
 * formats
 */
class CSVWriter : Writer {

	this(in string outputFileName)
	{
		super(outputFileName);
		_fh = File(outputFileName, "w");
	}

	override void write(Record rec)
	{
		_fh.write(join(rec.fieldValues, ";"), "\n");
	}

	~this() { _fh.close(); }
}

/*********************************************
 * in this case, each record is displayed as an ASCII table
 */
class TXTWriter : Writer {

	this(in string outputFileName)
	{
		super(outputFileName);
		_fh = File(outputFileName, "w");
	}

	override void write(Record rec)
	{
		string[] names, values;

		foreach (Field f; rec)
		{
			auto length = max(f.length, f.name.length);

			names  ~= f.name.leftJustify(length);
			values  ~= f.value.strip().leftJustify(length);
		}
		_fh.writefln("%s\n%s\n", join(names, "|"), join(values, "|"));
	}

	~this() { _fh.close(); }
}


/*********************************************
 * factory method for creating object matching
 * desired format
 */
Writer writer(in string output = "", in string mode = "txt")
{
	switch(mode)
	{
		case "html": return new HTMLWriter(output);
		case "csv" : return new CSVWriter(output);
		case "txt" : return new TXTWriter(output);
		case "xlsx": return new XLSXWriter(output);
		case "sql" : return new TXTWriter(output);
		default:
			throw new Exception("writer unknown mode %s".format(mode));
	}
}




unittest {

	auto reader = new Reader("./local/test1", r"./local/hot203.xml", (line => line[0..3] ~ line[11..13]));
	auto writer = writer("test.html", "html");

	reader.ignore_pattern = "^BKS";


	foreach (rec; reader) {
		writer.write(rec);
	}


}
