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
import rbf.config;
import rbf.writers.xlsxwriter;
import rbf.writers.csvwriter;
import rbf.writers.txtwriter;
import rbf.writers.htmlwriter;
import rbf.writers.tagwriter;
import rbf.writers.identwriter;
import rbf.writers.latexwriter;

/*********************************************
 * Orientation for printing out data:
 * 		horizontal: values per row
 * 		vertical: values per colmun
 */
enum Orientation { Horizontal, Vertical }

/*********************************************
 * writer class for writing to various ouput
 * formats
 */
abstract class Writer {
private:

	string _outputFileName; 			// name of the file we want to create
	//string _zipperExe;						// name & path of the executable used to create zip

package:

	File _fh; 										/// file handle on output file if any
	string _previousRecordName;		/// sometimes, we need to keep track of the previous record written
	Orientation _orientation; 		/// manage how information is printed

public:

	OutputFeature outputFeature;  /// specifics data for chosen output format


	/**
	 * creates a new Writer object for converting record-based files
	 *
	 Params:
	 outputFileName = name of the output file (or database name in case of sqlite3)
	 create = true if file is created during constructor
	 */
	this(in string outputFileName, in bool create = true)
	{
		// we might use standard output. So need to check out
		_outputFileName = outputFileName;

		if (outputFileName != "") {
			_outputFileName = outputFileName;
			if (create) _fh = File(_outputFileName, "w");
		}
		else
			_fh = stdout;

		// default orientation is horizontal
		//_orientation = Orientation.Horizontal;
		_orientation = Orientation.Vertical;
	}

	@property Orientation orientation() { return _orientation; }
	@property void orientation(Orientation o) { _orientation = o; }

	// should be implemented by derived classes
	abstract void write(Record rec);

	void open() {
		_fh = File(_outputFileName, "w");
	}
	void close() {
		// close handle if not stdout
		if (_outputFileName != "") _fh.close();
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
		case "html"  : return new HTMLWriter(output);
		case "csv"   : return new CSVWriter(output);
		case "txt"   : return new TXTWriter(output);
		case "xlsx"  : return new XLSXWriter(output, layout);
		case "sql"   : return new TXTWriter(output);
		case "tag"   : return new TAGWriter(output);
		case "latex" : return new LatexWriter(output);
		case "ident" : return new IdentWriter(output);
		default:
			throw new Exception("error: writer unknown mode <%s>".format(mode));
	}
}
