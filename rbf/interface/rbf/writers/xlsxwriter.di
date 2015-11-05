// D import file generated from 'source/rbf/writers/xlsxwriter.d'
module rbf.writers.xlsxwriter;
pragma (msg, "========> Compiling module ", "rbf.writers.xlsxwriter");
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.array;
import std.zip;
import std.conv;
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;
import rbf.writers.xlsxformat;
class XLSXWriter : Writer
{
	private 
	{
		string _xlsxFilename;
		string _xlsxDir;
		string[] _worksheets;
		ContentTypes _contentTypesFile;
		Workbook _workbookFile;
		Rels _relsFile;
		WorkbookRels _workbookRelsFile;
		Worksheet[string] _worksheetFile;
		bool[string] _createdWorksheet;
		void _create_zip()
		{
			chdir(_xlsxDir);
			auto result = std.process.execute([outputFeature.zipper, "-r", "../" ~ _xlsxFilename, "."]);
			if (result.status != 0)
				throw new Exception("zip command failed:\x0a", result.output);
			chdir("..");
			rmdirRecurse(_xlsxDir);
		}
		void _create_worksheet(Record rec)
		{
			_worksheetFile[rec.name] = new Worksheet(_xlsxDir, rec.name);
			_worksheetFile[rec.name].startRow();
			_worksheetFile[rec.name].strCell(format("%s: %s", rec.name, rec.meta.description));
			_worksheetFile[rec.name].endRow();
			_worksheetFile[rec.name].startRow();
			rec.each!((f) => _worksheetFile[rec.name].strCell(f.description));
			_worksheetFile[rec.name].endRow();
			_worksheetFile[rec.name].startRow();
			rec.each!((f) => _worksheetFile[rec.name].numCell(to!string(f.context.index + 1)));
			_worksheetFile[rec.name].endRow();
			_worksheetFile[rec.name].startRow();
			rec.each!((f) => _worksheetFile[rec.name].strCell(format("%s-%d", f.type.meta.name, f.length)));
			_worksheetFile[rec.name].endRow();
			_worksheetFile[rec.name].startRow();
			rec.each!((f) => _worksheetFile[rec.name].strCell(format("%s", f.name)));
			_worksheetFile[rec.name].endRow();
		}
		public 
		{
			this(string outputFileName, Layout layout)
			{
				super(outputFileName, false);
				_xlsxFilename = std.path.baseName(outputFileName);
				_xlsxDir = "./%s.%d".format(_xlsxFilename, std.datetime.Clock.currStdTime());
				mkdir(_xlsxDir);
				mkdir(_xlsxDir ~ "/_rels");
				mkdir(_xlsxDir ~ "/xl");
				mkdir(_xlsxDir ~ "/xl/_rels");
				mkdir(_xlsxDir ~ "/xl/worksheets");
				_contentTypesFile = new ContentTypes(_xlsxDir);
				_workbookFile = new Workbook(_xlsxDir);
				_workbookRelsFile = new WorkbookRels(_xlsxDir);
				_relsFile = new Rels(_xlsxDir);
			}
			override void prepare()
			{
			}
			override void write(Record record)
			{
				if (record.meta.skip)
					return ;
				if (!(record.name in _createdWorksheet))
				{
					_createdWorksheet[record.name] = true;
					_create_worksheet(record);
				}
				_worksheetFile[record.name].startRow();
				foreach (field; record)
				{
					if (field.type.meta.stringType == "string")
					{
						_worksheetFile[record.name].strCell(field.value);
					}
					else
					{
						_worksheetFile[record.name].numCell(field.value);
					}
				}
				_worksheetFile[record.name].endRow();
			}
			override void close()
			{
				foreach (recName; sort(_worksheetFile.keys))
				{
					_contentTypesFile.fill(recName);
					_workbookFile.fill(recName);
					_workbookRelsFile.fill(recName);
					_worksheetFile[recName].close;
				}
				_contentTypesFile.close;
				_workbookFile.close;
				_workbookRelsFile.close;
				_relsFile.close;
				_create_zip();
			}
		}
	}
}
