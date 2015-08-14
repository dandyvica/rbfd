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
		}
	}
}
class HTMLWriter : Writer
{
	this(in string outputFileName);
	override void write(Record rec);
	~this();
}
class CSVWriter : Writer
{
	this(in string outputFileName);
	override void write(Record rec);
	~this();
}
class TXTWriter : Writer
{
	this(in string outputFileName);
	override void write(Record rec);
	~this();
}
Writer writer(in string output = "", in string mode = "txt");
