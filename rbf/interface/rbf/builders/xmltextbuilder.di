// D import file generated from 'source/rbf/builders/xmltextbuilder.d'
module rbf.builders.xmltextbuilder;
pragma (msg, "========> Compiling module ", "rbf.builders.xmltextbuilder");
import std.stdio;
import std.file;
import std.string;
import std.xml;
import std.conv;
import std.exception;
import std.algorithm;
import std.regex;
import std.array;
import std.path;
import rbf.errormsg;
import rbf.log;
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.builders.xmlcore;
import rbf.builders.xmlbuilder;
class RbfTextBuilder : RbfBuilder
{
	File _fh;
	string inputFile;
	string meta;
	string orphanMode;
	Sanitizer[string][string] sanitizer;
	this(string xmlFile);
	void processInputFile();
	private void _sanitizeData(string[string] data, string tag);
}
