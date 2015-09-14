// D import file generated from 'source/writers/txtwriter.d'
module rbf.writers.txtwriter;
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
import rbf.writers.writer;
class TXTWriter : Writer
{
	private 
	{
		string _previousRecordName;
		public 
		{
			this(in string outputFileName);
			override void write(Record rec);
			override void close();
		}
	}
}
