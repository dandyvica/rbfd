// D import file generated from 'source/writer.d'
module rbf.writer;
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;
import rbf.field;
import rbf.record;
import rbf.reader;
import rbf.xlsxwriter;
abstract class Writer
{
	private 
	{
		File _fh;
		string _outputFileName;
		public 
		{
			this(in string outputFileName);
			abstract void write(Record rec);
			abstract void close();
		}
	}
}
class HTMLWriter : Writer
{
	this(in string outputFileName);
	override void write(Record rec);
	override void close();
}
class CSVWriter : Writer
{
	this(in string outputFileName);
	override void write(Record rec);
	override void close();
}
class TXTWriter : Writer
{
	this(in string outputFileName);
	override void write(Record rec);
	override void close();
}
Writer writer(in string output = "", in string mode = "txt");
