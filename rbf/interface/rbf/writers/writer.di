// D import file generated from 'source/rbf/writers/writer.d'
module rbf.writers.writer;
pragma (msg, "========> Compiling module ", "rbf.writers.writer");
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
import rbf.writers.identwriter;
import rbf.writers.latexwriter;
enum Orientation 
{
	Horizontal,
	Vertical,
}
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
			Orientation _orientation;
			public 
			{
				this(in string outputFileName, in bool create = true);
				@property string zipper();
				@property void zipper(string zipperExe);
				@property Orientation orientation();
				@property void orientation(Orientation o);
				abstract void write(Record rec);
				void open();
				void close();
			}
		}
	}
}
Writer writerFactory(in string output, in string mode, Layout layout);
