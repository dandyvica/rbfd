module rbf.writers.xlsxwriter;

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.array;
import std.zip;

import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;
import rbf.writers.xlsxformat;

class XLSXWriter : Writer {
private:

	string _xlsxFilename;		/// Excel worksheet file name
	string _xlsxDir;				/// directory used to gather all Excel files
	string[] _worksheets;   /// list of worksheets for the Excel file

	ContentTypes _contentTypesFile;
	Workbook _workbookFile;
	Rels _relsFile;
	WorkbookRels _workbookRelsFile;
	Worksheet[string]	_worksheetFile;

	// create the zip archive as an XLSX file
	void _create_zip() {
		// ch dir to XLSX directory
		chdir(_xlsxDir);

		// create zip
		auto result = std.process.execute([Writer.zipper, "-r", "../" ~ _xlsxFilename, "."]);
		if (result.status != 0)
			throw new Exception("zip command failed:\n", result.output);

		// now it's sace to remove all files
		chdir("..");
		rmdirRecurse(_xlsxDir);
	}

public:

	this(string outputFileName, Layout layout)
	{

		super(outputFileName, false);

		// save file name
		_xlsxFilename = std.path.baseName(outputFileName);

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
		_workbookFile = new Workbook(_xlsxDir);
		_workbookRelsFile = new WorkbookRels(_xlsxDir);

		// not this one
		_relsFile = new Rels(_xlsxDir);


		// for each record in the layout, fill data for file depending on worksheets
		// only for records we want to keep
		foreach (rec; layout) {
			if (rec.keep) {
				_contentTypesFile.fill(rec.name);
				_workbookFile.fill(rec.name);
				_workbookRelsFile.fill(rec.name);

				// and also create sheets. We need an assoc. array to keep track
				// of link between records and sheets
				_worksheetFile[rec.name] = new Worksheet(_xlsxDir, rec.name);

				// then create header (record name & record description)
				_worksheetFile[rec.name].startRow();
				_worksheetFile[rec.name].strCell(format("%s: %s", rec.name, rec.description));
				_worksheetFile[rec.name].endRow();

				// then create description columns and fields
				_worksheetFile[rec.name].startRow();
				rec.each!(f => _worksheetFile[rec.name].strCell(f.description));
				_worksheetFile[rec.name].endRow();

				_worksheetFile[rec.name].startRow();
				rec.each!(f => _worksheetFile[rec.name].strCell(format(`%s (%s,%d)`,
					f.name, f.declaredType, f.length)));
				_worksheetFile[rec.name].endRow();
			}
		}

	}

	override void write(Record record)
	{
		// new excel row
		_worksheetFile[record.name].startRow();

		// for each record, just write data to worksheet
		// depending on its type, an Excel cell doesn't contain the same XML
		foreach (field; record) {
			if (field.fieldType.rootType == RootType.STRING)
			{
				_worksheetFile[record.name].strCell(field.value);
			}
			else
			{
				_worksheetFile[record.name].numCell(field.value);
			}
		}

		// end up row
		_worksheetFile[record.name].endRow();
	}

	override void close()
	{
		// gracefully end all xlsx files
		_contentTypesFile.close;
		_workbookFile.close;
		_workbookRelsFile.close;
		_relsFile.close;

		foreach (sheet; _worksheetFile) {
			sheet.close;
		}

		// finally create zip
		_create_zip();


	}


}
