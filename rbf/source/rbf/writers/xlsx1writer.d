module rbf.writers.xlsx1writer;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.array;
import std.zip;
import std.conv;

import rbf.errormsg;
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;
import rbf.writers.xlsxformat;

class XLSX1Writer : Writer 
{
private:

	string _xlsxFilename;	/// Excel worksheet file name
	string _xlsxDir;		/// directory used to gather all Excel files
	string[] _worksheets;   /// list of worksheets for the Excel file

    /// list of all objects used when creating particular type of an Excel underlying file
	ContentTypes _contentTypesFile;
	Workbook _workbookFile;
	Rels _relsFile;
	WorkbookRels _workbookRelsFile;
	Worksheet[string]	_worksheetFile;

	bool[string] _createdWorksheet;  /// true as soon as a sheet is created

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
			throw new Exception("zip command failed:\n", result.output);

		// now it's time to remove all files
		chdir("..");
		rmdirRecurse(_xlsxDir);
	}

	/** 
     * Create a worksheet with headers
	 *
	 * Params:
	 *  rec = Record object
     *
	 */
	void _create_worksheet(Record rec) 
    {
		// and also create sheets. We need an assoc. array to keep track
		// of link between records and sheets
		_worksheetFile[rec.name] = new Worksheet(_xlsxDir, rec.name);

		// then create header (record name & record description)
		_worksheetFile[rec.name].startRow();
		_worksheetFile[rec.name].strCell!string(format("%s: %s", rec.name, rec.meta.description));
		_worksheetFile[rec.name].endRow();

		// create field description row
		_worksheetFile[rec.name].startRow();
		rec.each!(f => _worksheetFile[rec.name].strCell!string(f.description));
		_worksheetFile[rec.name].endRow();

		// create field type, length row
		_worksheetFile[rec.name].startRow();
		rec.each!(f => _worksheetFile[rec.name].strCell!string(format("%s-%d", f.type.meta.name, f.length)));
		_worksheetFile[rec.name].endRow();

		// create field name
		_worksheetFile[rec.name].startRow();
		rec.each!(f => _worksheetFile[rec.name].strCell!string(format("%s", f.name)));
		_worksheetFile[rec.name].endRow();
	}

public:

	/** 
     * Pre-create all necessary files comprised in an Excel file (SpreadsheetML XML format)
	 *
	 * Params:
	 * 	excelFileName = xlsx file name
	 *  layout = Layout object
     *
	 */
	this(string excelFileName)
	{

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

		// worksheet exist?
		if (record.name !in _createdWorksheet) 
        {
			_createdWorksheet[record.name] = true;
			_create_worksheet(record);
		}

		// new excel row
		_worksheetFile[record.name].startRow();

		// for each record, just write data to worksheet
		// depending on its type, an Excel cell doesn't contain the same XML
		foreach (field; record) 
        {
			if (field.type.meta.stringType == "string")
			{
				_worksheetFile[record.name].strCell!TVALUE(field.value);
			}
            /*
			else if (field.type.meta.stringType == "date")
			{
				_worksheetFile[record.name].dateCell(field.value);
			}
            */
			else
			{
				_worksheetFile[record.name].numCell(field.value);
			}
		}

		// end up row
		_worksheetFile[record.name].endRow();
	}

	/** 
     * When closing Excel file, create zip
     *
	 */
	override void close()
	{
		// gracefully end all xlsx files
		foreach (recName; sort(_worksheetFile.keys)) 
        {
			// fill metadata with record name
			_contentTypesFile.fill(recName);
			_workbookFile.fill(recName);
			_workbookRelsFile.fill(recName);

			// close sheet file
			_worksheetFile[recName].close;
		}

		// gracefully end all xlsx files
		_contentTypesFile.close;
		_workbookFile.close;
		_workbookRelsFile.close;
		_relsFile.close;

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

	auto writer = writerFactory("./test/world_data.xlsx", OutputFormat.excel1);
	writer.outputFeature.zipper = "/usr/bin/zip";

	foreach (rec; reader) { writer.write(rec); }

	writer.close();
}
