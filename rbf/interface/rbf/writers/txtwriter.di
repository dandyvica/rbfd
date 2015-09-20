// D import file generated from 'source/rbf/writers/txtwriter.d'
module rbf.writers.txtwriter;
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;
import rbf.field;
import rbf.record;
import rbf.writers.writer;
class TXTWriter : Writer
{
	public 
	{
		this(in string outputFileName);
		override void write(Record rec);
	}
}
