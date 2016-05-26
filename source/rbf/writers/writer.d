module rbf.writers.writer;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;

import rbf.errormsg;
import rbf.log;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.config;
import rbf.writers.boxwriter;
import rbf.writers.csvwriter;
import rbf.writers.htmlwriter;
import rbf.writers.identwriter;
import rbf.writers.sqlite3writer;
import rbf.writers.sqlpostgres;
import rbf.writers.tagwriter;
import rbf.writers.templatewriter;
import rbf.writers.txtwriter;
import rbf.writers.xlsx1writer;
import rbf.writers.xlsx2writer;
import rbf.writers.xsdwriter;

// list of all possible output formats. For those formats, the settings XML file
// should define their 
enum OutputFormat { box, csv, html, ident, sql, postgres, tag, txt, excel1, excel2, xml, temp }

/*********************************************
 * writer base class for writing to various ouput formats
 */
abstract class Writer 
{
private:

	string _outputFileName; 		/// name of the output file we want to create

package:

	File _fh; 						/// file handle on output file if any
	string _previousRecordName;		/// sometimes, we need to keep track of the previous record written
                                    /// useful to gracefully end ascii tables
    bool useFile = true;            /// in some situations (e.g.: PostgreSQL), we don't write into a file
                                    /// but rather a DB. So we don't use a file

public:

    Config configFromXMLFile;       /// configuration already read from configuration file
    string inputFileName;
	OutputFeature outputFeature;    /// specific data for chosen output format


	/**
	 * creates a new Writer object for converting record-based files to output format
	 *
	 Params:
    	 outputFileName = name of the output file (or database name in case of sqlite3)
    	 create = true if file is created during constructor
	 */
	this(in string outputFileName, in bool create = true)
	{
		// we might use standard output. So need to check out
        // if outputFileName is not specified, output to stdout
		_outputFileName = outputFileName;
		if (outputFileName != "") 
        {
			_outputFileName = outputFileName;
			if (create) 
            {
                _fh = File(_outputFileName, "w");
                log.log(LogLevel.INFO, MSG019, outputFileName);
            }
		}
		else
        {
			_fh = stdout;
        }
	}

    this() { useFile = false; }

	// should be implemented by derived classes
	abstract void prepare(Layout layout);
	abstract void build(string outputFileName);
	abstract void write(Record rec);

	void open() 
    {
		if (useFile) _fh = File(_outputFileName, "w");
	}
	void close() 
    {
		// close handle if not stdout
		if (_outputFileName != "" && useFile) _fh.close();
	}

}

/*********************************************
 * factory method for creating object matching
 * desired format
 */
Writer writerFactory(in string output, in OutputFormat fmt)
{
	final switch(fmt)
	{
		case OutputFormat.box   : return new BoxWriter(output);
		case OutputFormat.csv   : return new CSVWriter(output);
		case OutputFormat.excel1: return new XLSX1Writer(output);
		case OutputFormat.excel2: return new XLSX2Writer(output);
		case OutputFormat.html  : return new HTMLWriter(output);
		case OutputFormat.ident : return new IdentWriter(output);
		case OutputFormat.sql   : return new Sqlite3Writer(output);
		case OutputFormat.postgres : return new SqlPGWriter(output);
		case OutputFormat.tag   : return new TAGWriter(output);
		case OutputFormat.temp  : return new TemplateWriter(output);
		case OutputFormat.txt   : return new TXTWriter(output);
		case OutputFormat.xml   : return new XmlWriter(output);
	}
}
