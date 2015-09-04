// D import file generated from 'source/writers/htmlwriter.d'
module rbf.writers.htmlwriter;
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
class HTMLWriter : Writer
{
	this(in string outputFileName);
	override void write(Record rec);
	override void close();
}
