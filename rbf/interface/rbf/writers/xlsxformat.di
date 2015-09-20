// D import file generated from 'source/rbf/writers/xlsxformat.d'
module rbf.writers.xlsxformat;
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.array;
import std.zip;
class XlsxEntity
{
	private 
	{
		File _fh;
		string _fileName;
		public 
		{
			this(string fileName);
			void close();
		}
	}
}
class ContentTypes : XlsxEntity
{
	this(string path);
	void fill(string worksheetName);
	override void close();
}
class Workbook : XlsxEntity
{
	private 
	{
		ushort sheetIndex;
		public 
		{
			this(string path);
			void fill(string worksheetName);
			override void close();
		}
	}
}
class Worksheet : XlsxEntity
{
	this(string path, string worksheetName);
	void startRow();
	void endRow();
	void strCell(string cellValue);
	void numCell(string cellValue);
	override void close();
}
class Rels : XlsxEntity
{
	this(string path);
	void fill(string worksheetName);
	override void close();
}
class WorkbookRels : XlsxEntity
{
	private 
	{
		ushort sheetIndex;
		public 
		{
			this(string path);
			void fill(string worksheetName);
			override void close();
		}
	}
}
