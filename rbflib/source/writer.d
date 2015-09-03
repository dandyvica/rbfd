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
import rbf.conf;

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
	abstract void close();

}

/*********************************************
 * each record is displayed as an HTML table
 */
class HTMLWriter : Writer {

	this(in string outputFileName)
	{
		super(outputFileName);
		_fh = File(outputFileName, "w");

		// bootstrap header
		_fh.writeln(`<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">`);
		_fh.writeln(`<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css"></head>`);
		_fh.writeln(`<body role="document"><div class="container">`);
	}

	override void write(Record rec)
	{
		string names="", values="";

		// write record name & description
		_fh.writefln(`<h2><span class="label label-primary">%s - %s</span></h2>`,
					rec.name, rec.description);

		// write fields as a HTML table
		_fh.write(`<table class="table table-striped">`);
		foreach (Field f; rec)
		{
			names ~= "<th>" ~ f.name ~ "</th>";
			values ~= "<td>" ~ f.value ~ "</td>";
		}
		_fh.writefln("<thead><tr>%s</tr></thead>", names);
		_fh.writefln("<tbody><tr>%s</tr></tbody>", values);

		_fh.write("</table>");
	}

	// end up HTML tags
	override void close()
	{
		_fh.writeln("</div></body></html>");
		_fh.close();
	}
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

	override void close() { _fh.close(); }
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
		/*
		string[] names, values;

		// preallocate as we know how much fields we've got
		names.length = rec.size;
		values.length = rec.size;

		uint i = 0;
		foreach (Field f; rec)
		{
			//auto length = max(f.length, f.name.length);
			//names  ~= f.name.leftJustify(f.cell_length);
			//values  ~= f.value.leftJustify(f.cell_length);
			names[i] = f.name.leftJustify(f.cell_length);
			values[i++] = f.value.leftJustify(f.cell_length);
		}
		_fh.writefln("%s\n%s\n", join(names, "|"), join(values, "|"));
		*/
		uint i = 0;
		foreach (name; rec.fieldNames) {
			_fh.writef("%-*s|", rec[i++].cell_length, name);
		}
		_fh.writeln();

		i = 0;
		foreach (value; rec.fieldValues) {
			_fh.writef("%-*s|", rec[i++].cell_length, value);
		}
		_fh.writeln("\n");

	}

	override void close() { _fh.close(); }
}


/*********************************************
 * factory method for creating object matching
 * desired format
 */
Writer writer(in string output, in string mode)
{
	switch(mode)
	{
		case "html": return new HTMLWriter(output);
		case "csv" : return new CSVWriter(output);
		case "txt" : return new TXTWriter(output);
		case "xlsx": return new XLSXWriter(output);
		case "sql" : return new TXTWriter(output);
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


	auto writer1 = writer("test.html", "html");
	foreach (rec; reader) { writer1.write(rec); }

	auto writer2 = writer("test.txt", "txt");
	foreach (rec; reader) { writer2.write(rec); }

	auto writer3 = writer("test.csv", "csv");
	foreach (rec; reader) { writer3.write(rec); }

	auto writer4 = writer("test.xlsx", "xlsx");
	foreach (rec; reader) { writer4.write(rec); }
	writer4.close();
}
