module rbf.writers.xlsx1writer;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.range;
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
import rbf.writers.xlsxwriter;

class XLSX1Writer : XLSXWriter 
{
private:

	Worksheet[string]	_worksheetFile;
	bool[string] _createdWorksheet;  /// true as soon as a sheet is created

	/** 
     * Create a worksheet with headers
	 *
	 * Params:
	 *  rec = Record object
     *
	 */
	void _createWorksheet(Record rec) 
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
        // create Excel directory structure
		super(excelFileName);
	}

	/** 
     * Create all worksheets corresponding to records in layout
	 *
	 * Params:
	 *  layout = Layout object
     *
	 */
	override void prepare(Layout layout) 
    {
        // for each record we don't skip, create worksheet
        //layout[].filter!(rec => !rec.meta.skip).each!(rec => _createWorksheet(rec));
    }

    override void build(string outputFileName) {}

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

		// worksheet doesn't still exist? If no, juste create it
		if (record.name !in _createdWorksheet) 
        {
			_createdWorksheet[record.name] = true;
			_createWorksheet(record);
		}

        // write record to worksheet
        _writeRecordToWorksheet(record, _worksheetFile[record.name]);

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

	auto writer = writerFactory("./test/world_data.xlsx", OutputFormat.excel1);

	foreach (rec; reader) { writer.write(rec); }

	writer.close();
}
