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
import rbf.reader;
import rbf.conf;
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
		package 
		{
			File _fh;
			public 
			{
				this(in string outputFileName);
				abstract void write(Record rec);
				abstract void close();
			}
		}
	}
}
Writer writer(in string output, in string mode);
