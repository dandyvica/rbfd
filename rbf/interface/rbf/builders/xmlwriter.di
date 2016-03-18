// D import file generated from 'source/rbf/writers/xmlwriter.d'
module rbf.writers.xmlwriter;
pragma (msg, "========> Compiling module ", "rbf.writers.xmlwriter");
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.path;
import std.xml;
import rbf.errormsg;
import rbf.log;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;
immutable xmlField = "<%s>%s</%s>";
immutable xmlBeginRecord = "<RECORD_%s>";
immutable xmlEndRecord = "</RECORD_%s>";
class XmlWriter : Writer
{
	string _xsdFileName;
	File _xsd;
	this(in string outputFileName);
	override void prepare(Layout layout);
	override void build(string outputFileName);
	override void write(Record rec);
	override void close();
}
