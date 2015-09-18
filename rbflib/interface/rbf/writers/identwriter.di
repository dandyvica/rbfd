// D import file generated from 'source/writers/identwriter.d'
module rbf.writers.identwriter;
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;
import rbf.field;
import rbf.record;
import rbf.writers.writer;
class IdentWriter : Writer
{
	this(in string outputFileName);
	override void write(Record rec);
}
