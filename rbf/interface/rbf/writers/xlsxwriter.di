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
		void _create_zip();
		public 
		{
			this(string outputFileName, Layout layout);
			override void write(Record record);
			override void close();
		}
	}
}
