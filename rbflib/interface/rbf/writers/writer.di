// D import file generated from 'source/writers/writer.d'
module rbf.writers.writer;
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.xlsxwriter;
import rbf.writers.csvwriter;
import rbf.writers.txtwriter;
import rbf.writers.htmlwriter;
import rbf.writers.tagwriter;
abstract class Writer
{
	private 
	{
		string _outputFileName;
		string _zipperExe;
		package 
		{
			File _fh;
			string _previousRecordName;
			public 
			{
				this(in string outputFileName);
				@property string zipper();
				@property void zipper(string zipperExe);
				abstract void write(Record rec);
				abstract void close();
			}
		}
	}
}
Writer writer(in string output, in string mode, Layout layout);
