module rbf.writer;

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;

import rbf.field;
import rbf.record;

import rbf.reader;

//import rbf.xlsxwriter;

//import util.common;

abstract class Writer {
private:

	File _fh; // file handle on output file if any
	string _outputFileName; // name of the file we want to create
	
public:
	this(in string outputFileName)
	{
		_outputFileName = outputFileName;
	}
	
	abstract void write(Record rec);

}

class HTMLWriter : Writer {
	
	this(in string outputFileName)
	{
		super(outputFileName);
		if (outputFileName == "") _fh = stdout; else _fh = File(outputFileName, "w");
		_fh.write("<html><head><link href=\"../css/rbf.css\" rel=\"stylesheet\" type=\"text/css\"></head><body>\n");
	}
	
	override void write(Record rec) 
	{
		string names="", values="";

		_fh.write("<table>");
		foreach (Field f; rec)
		{
			names ~= "<tr>" ~ f.name ~ "</tr>";
			values ~= "<tr>" ~ f.value ~ "</tr>";
		}
		_fh.write(names, "\n", values);
		_fh.write("</table>");
	}
	
	~this() { _fh.close(); }
}

class CSVWriter : Writer {
	
	this(in string outputFileName)
	{
		super(outputFileName);
		if (outputFileName == "") _fh = stdout; else _fh = File(outputFileName, "w");
	}
			
	override void write(Record rec) 
	{ 
		_fh.write(join(rec.fieldValues, ";"), "\n");
	}
	
	~this() { _fh.close(); }
}

class TXTWriter : Writer {
	
	this(in string outputFileName)
	{
		super(outputFileName);
		if (outputFileName == "") _fh = stdout; else _fh = File(outputFileName, "w");
	}
	
	override void write(Record rec) 
	{ 
		string[] names, values;
	
		foreach (Field f; rec)
		{
			auto length = max(f.length, f.name.length);
			
			names  ~= f.name.leftJustify(length);
			values  ~= f.value.strip().leftJustify(length);
		}	
		_fh.writefln("%s\n%s\n", join(names, "|"), join(values, "|"));
		//_fh.writeln(join(values, "|"));
	}
	
	~this() { _fh.close(); }
}


Writer writer(in string output = "", in string mode = "txt")
{
	switch(mode)
	{
		case "html": return new HTMLWriter(output);
		case "csv" : return new CSVWriter(output);
		case "txt" : return new TXTWriter(output);
		//case "xlsx": return new XLSXWriter(output);
		case "sql" : return new TXTWriter(output);
		default:
			throw new Exception("writer unknown mode %s".format(mode));			
	}
}




unittest {
	
	auto rbf = new Reader("/home/m330421/data/files/bsp/SE.STO.057.PROD.1505281131", r"/home/m330421/data/local/xml/hot203.xml", (line => line[0..3] ~ line[11..13]));
	auto writer = writer("test.html", "html");
	
	rbf.ignore_pattern = "^BKS";

	
	foreach (rec; rbf) {
		writer.write(rec);
	}
	

}