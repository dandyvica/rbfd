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
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;
import rbf.writers.xlsxformat;

class XLSX2Writer : Writer {
private:

	string _xlsxFilename;	/// Excel worksheet file name
	string _xlsxSheetName;	/// Excel worksheet only sheet name
	string _xlsxDir;		/// directory used to gather all Excel files

    /// list of all objects used when creating particular type of an Excel underlying file
    ContentTypes _contentTypesFile;
    Workbook _workbookFile;
    Rels _relsFile;
    WorkbookRels _workbookRelsFile;
    Worksheet	_worksheetFile;

	/** 
     * Creation of a zip file (xlsx = zip file) from all created files
     *
	 */
	void _create_zip() 
    {
		// ch dir to XLSX directory
		chdir(_xlsxDir);

        // log
        stderr.writeln(MSG011);

		// create zip
		auto result = std.process.execute([outputFeature.zipper, "-r", "../" ~ _xlsxFilename, "."]);
		if (result.status != 0)
			throw new Exception(MSG045.format(result.output));

		// now it's time to remove all files
		chdir("..");
		rmdirRecurse(_xlsxDir);
	}

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

		super(excelFileName, false);

        // log
        stderr.writeln(MSG012);

		// save file name
		_xlsxFilename = baseName(excelFileName);

        // and buld sheet name
        _xlsxSheetName = stripExtension(_xlsxFilename);
        log.log(LogLevel.INFO, MSG049, _xlsxSheetName);

		// create a unique XLSX directory structure
		_xlsxDir = "./%s.%d".format(_xlsxFilename, std.datetime.Clock.currStdTime());
		mkdir(_xlsxDir);
		mkdir(_xlsxDir ~ "/_rels");
		mkdir(_xlsxDir ~ "/xl");
		mkdir(_xlsxDir ~ "/xl/_rels");
		mkdir(_xlsxDir ~ "/xl/worksheets");

		// create xlsx files contained in an Excel file
		// those ones contain sheet names
		_contentTypesFile = new ContentTypes(_xlsxDir);
		_workbookFile     = new Workbook(_xlsxDir);
		_workbookRelsFile = new WorkbookRels(_xlsxDir);

		// not this one
		_relsFile = new Rels(_xlsxDir);

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
		if (record.meta.skip) return;

		// new excel row
		_worksheetFile.startRow();

		// for each record, just write data to worksheet
		// depending on its type, an Excel cell doesn't contain the same XML
		foreach (field; record) 
        {
			if (field.type.meta.stringType == "string")
			{
				_worksheetFile.strCell!TVALUE(field.value);
			}
            /*
			else if (field.type.meta.stringType == "date")
			{
				_worksheetFile.dateCell(field.value);
			}
            */
			else
			{
				_worksheetFile.numCell(field.value);
			}
		}

		// end up row
		_worksheetFile.endRow();
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

		// gracefully end all xlsx files
		_contentTypesFile.close;
		_workbookFile.close;
		_workbookRelsFile.close;
		_relsFile.close;
		_worksheetFile.close;

		// finally create zip
		_create_zip();
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
