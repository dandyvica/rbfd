// D import file generated from 'source/writers/csvwriter.d'
module rbf.writers.csvwriter;
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;
import rbf.field;
import rbf.record;
import rbf.writers.writer;
class CSVWriter : Writer
{
	this(in string outputFileName);
	override void write(Record rec);
}
