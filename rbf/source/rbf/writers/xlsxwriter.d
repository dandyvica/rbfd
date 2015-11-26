module rbf.writers.xlsxwriter;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.array;
import std.zip;
import std.conv;
import std.xml;

import rbf.errormsg;
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;
import rbf.writers.xlsxformat;

class XLSXWriter : Writer 
{
package:

	string _xlsxFilename;	/// Excel worksheet file name
	string _xlsxDir;		/// directory used to gather all Excel files

    /// list of all objects used when creating particular type of an Excel underlying file
	ContentTypes _contentTypesFile;
	Workbook _workbookFile;
	Rels _relsFile;
	WorkbookRels _workbookRelsFile;

	/** 
     * Creation of a zip file (xlsx = zip file) from all created files
     *
	 */
	void _createZip() 
    {
		// ch dir to XLSX directory
		chdir(_xlsxDir);

        // log
        stderr.writeln(MSG011);

		// create zip
		auto result = std.process.execute([outputFeature.zipper, "-r", "../" ~ _xlsxFilename, "."]);
		if (result.status != 0)
			throw new Exception("zip command failed:\n", result.output);

		// now it's time to remove all files
		chdir("..");
		rmdirRecurse(_xlsxDir);
	}

	/** 
     * Create a worksheet with headers
	 *
	 * Params:
	 *  rec = Record object to write to Excel sheet
     *  worksheetFile = Worksheet file object
     *
	 */
    void _writeRecordToWorksheet(Record record, Worksheet worksheetFile)
    {
		// new excel row
		worksheetFile.startRow();

		// for each record, just write data to worksheet
		// depending on its type, an Excel cell doesn't contain the same XML
		foreach (field; record) 
        {
			if (field.type.meta.stringType == "string")
			{
				worksheetFile.strCell!TVALUE(field.value.encode);
			}
            /*
			else if (field.type.meta.stringType == "date")
			{
				worksheetFile.dateCell(field.value.encode);
			}
            */
			else
			{
				worksheetFile.numCell(field.value.encode);
			}
		}

		// end up row
		worksheetFile.endRow();
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

        // don't create output file name
		super(excelFileName, false);

        // log
        stderr.writeln(MSG012);

		// save file name
		_xlsxFilename = std.path.baseName(excelFileName);

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

	}

	override void prepare(Layout layout) {}


	/** 
     * When closing Excel file, create zip
     *
	 */
	override void close()
	{
		// gracefully end all xlsx files
		_contentTypesFile.close;
		_workbookFile.close;
		_workbookRelsFile.close;
		_relsFile.close;

		// finally create zip
		_createZip();
	}

}
unittest {

	writeln("========> testing ", __FILE__);

	import rbf.reader;
	import std.regex;

	auto layout = new Layout("./test/world_data.xml");
	auto reader = new Reader("./test/world.data", layout);

	auto writer = writerFactory("./test/world_data.xlsx", OutputFormat.excel1);
	writer.outputFeature.zipper = "/usr/bin/zip";

	foreach (rec; reader) { writer.write(rec); }

	writer.close();
}
