// D import file generated from 'source/rbf/writers/writer.d'
module rbf.writers.writer;
pragma (msg, "========> Compiling module ", "rbf.writers.writer");
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;
import rbf.errormsg;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.config;
import rbf.writers.xlsxwriter;
import rbf.writers.csvwriter;
import rbf.writers.txtwriter;
import rbf.writers.boxwriter;
import rbf.writers.htmlwriter;
import rbf.writers.tagwriter;
import rbf.writers.identwriter;
import rbf.writers.sqlite3writer;
abstract class Writer
{
	private 
	{
		string _outputFileName;
		package 
		{
			File _fh;
			string _previousRecordName;
			public 
			{
				OutputFeature outputFeature;
				this(in string outputFileName, in bool create = true);
				abstract void prepare(Layout layout);
				abstract void write(Record rec);
				void open();
				void close();
			}
		}
	}
}
Writer writerFactory(in string output, in string mode, Layout layout);
