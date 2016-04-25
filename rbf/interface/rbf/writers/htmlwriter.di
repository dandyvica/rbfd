// D import file generated from 'source/rbf/writers/htmlwriter.d'
module rbf.writers.htmlwriter;
pragma (msg, "========> Compiling module ", "rbf.writers.htmlwriter");
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;
import std.array;
import std.functional;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.config;
import rbf.writers.writer;
immutable formatter = "format(\"<%s>%s</%s>\",a,b,a)";
alias htmlRowBuilder = binaryFun!formatter;
class HTMLWriter : Writer
{
	this(in string outputFileName)
	{
		super(outputFileName);
	}
	override void prepare(Layout layout)
	{
		_fh.writeln("<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\">");
		_fh.writeln("<link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css\"></head>");
		_fh.writeln("<body role=\"document\"><div class=\"container\">");
	}
	override void build(string outputFileName)
	{
	}
	override void write(Record rec)
	{
		if (outputFeature.orientation == Orientation.horizontal)
			_writeH(rec);
		else
			_writeV(rec);
	}
	override void close()
	{
		_fh.writeln("</table></div></body></html>");
		Writer.close();
	}
	private 
	{
		string _buildHTMLDataRow(Record rec)
		{
			return array(rec.fieldValues.map!((f) => htmlRowBuilder("td", f))).join("");
		}
		void _writeV(Record rec)
		{
			_fh.writefln("</table><h2><span class=\"label label-primary\">%s - %s</span></h2>", rec.meta.name, rec.meta.description);
			_fh.write("<table class=\"table table-striped\">");
			_fh.write("<tr><th>Index</th><th>Field</th><th>Description</th><th>Length</th><th>Type</th><th>Value</th></tr>");
			foreach (f; rec)
			{
				_fh.write("<tr><th>%s</th><th>%s</th><th>%s</th><th>%s</th><th>%s</th><th>%s</th></tr>".format(f.context.index + 1, f.name, f.description, f.length, f.type.meta.name, f.value));
			}
			_fh.write("</table>");
		}
		void _writeH(Record rec)
		{
			if (_previousRecordName != rec.name)
			{
				if (_previousRecordName != "")
				{
					_fh.writefln("</table>");
				}
				_fh.writefln("</table><h2><span class=\"label label-primary\">%s - %s</span></h2>", rec.name, rec.meta.description);
				_fh.write("<table class=\"table table-striped\">");
				auto headers = array(rec.fieldNames.map!((f) => htmlRowBuilder("th", f))).join("");
				_fh.writefln("<thead><tr>%s</tr></thead>", headers);
				auto desc = array(rec.fieldDescriptions.map!((f) => htmlRowBuilder("th", f))).join("");
				_fh.writefln("<tr>%s</tr>", desc);
				_fh.writefln("<tr>%s</tr>", _buildHTMLDataRow(rec));
				_previousRecordName = rec.name;
			}
			else
			{
				_fh.writefln("<tr>%s</tr>", _buildHTMLDataRow(rec));
			}
		}
	}
}
