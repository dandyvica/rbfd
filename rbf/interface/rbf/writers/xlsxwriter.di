// D import file generated from 'source\rbf\writers\xlsxwriter.d'
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
	package 
	{
		string _xlsxFilename;
		string _xlsxDir;
		ContentTypes _contentTypesFile;
		Workbook _workbookFile;
		Rels _relsFile;
		WorkbookRels _workbookRelsFile;
		void _createZip();
		void _writeRecordToWorksheet(Record record, Worksheet worksheetFile);
		public 
		{
			this(string excelFileName);
			override void prepare(Layout layout);
			override void close();
		}
	}
}
