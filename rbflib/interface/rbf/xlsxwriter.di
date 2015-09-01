// D import file generated from 'source/xlsxwriter.d'
module rbf.xlsxwriter;
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.array;
import std.zip;
import rbf.field;
import rbf.record;
import rbf.writer;
enum XlsxRowType : string
{
	XLSX_STRROW = "<c t=\"inlineStr\"><is><t>%s</t></is></c>",
	XLSX_NUMROW = "<c><v>%s</v></c>",
}
struct XLSXPattern
{
	string fileName;
	string fileString;
	string fileTag;
	string constructedTags = "";
}
class XLSXWriter : Writer
{
	private 
	{
		string _xlsxFilename;
		string _xlsxDir;
		string[] _worksheets;
		static XLSXPattern[string] pattern;
		string _toXLSXRow(string value, FieldType ft = FieldType.ALPHABETICAL);
		void _create_zip();
		public 
		{
			this(string outputFileName);
			override void write(Record record);
			override void close();
		}
	}
}
