module rbf.writers.xlsx2writer;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.array;
import std.zip;
import std.conv;
import std.path;

import rbf.errormsg;
import rbf.log;
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;
import rbf.writers.xlsxformat;
import rbf.writers.xlsxwriter;

class XLSX2Writer : XLSXWriter {
private:

	string _xlsxSheetName;	  /// Excel worksheet only sheet name
    Worksheet _worksheetFile; /// Excel worksheet

public:

	/** 
     * Pre-create all necessary files comprised in an Excel file (SpreadsheetML XML format)
	 *
	 * Params:
	 * 	excelFileName = xlsx file name
     *
	 */
	this(string excelFileName)
	{
        // create Excel directory structure
		super(excelFileName);

        // only a single sheet name here
        _xlsxSheetName = _xlsxFilename.stripExtension;

		// and also create sheets. We need an assoc. array to keep track
		// of link between records and sheets
		_worksheetFile = new Worksheet(_xlsxDir, _xlsxSheetName);
	}

	override void prepare(Layout layout) 
    {
    }

	/** 
     * Insert a row into an Excel worksheet
	 *
	 * Params:
	 *  rec = Record object
     *
	 */
	override void write(Record record)
	{
		// don't keep this record?
		//if (record.meta.skip) return;

        // write record to worksheet
        _writeRecordToWorksheet(record, _worksheetFile);
	}

	/** 
     * When closing Excel file, create zip
     *
	 */
	override void close()
	{
		// gracefully end all xlsx files
        _contentTypesFile.fill(_xlsxSheetName);
        _workbookFile.fill(_xlsxSheetName);
        _workbookRelsFile.fill(_xlsxSheetName);

        // close main worksheet file
		_worksheetFile.close;

		// close all files and create ZIP
		super.close;
	}

}
unittest {

	writeln("========> testing ", __FILE__);

	import rbf.reader;
	import std.regex;

	auto layout = new Layout("./test/world_data.xml");
	auto reader = new Reader("./test/world.data", layout);

	auto writer = writerFactory("./test/world_data.xlsx", OutputFormat.excel2);
	writer.outputFeature.zipper = "/usr/bin/zip";

	foreach (rec; reader) { writer.write(rec); }

	writer.close();
}
