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

/*********************************************
 * each record is displayed as an HTML table
 */
class HTMLWriter : Writer {

	this(in string outputFileName)
	{
		super(outputFileName);
		_fh = File(outputFileName, "w");

		// bootstrap header
		_fh.writeln(`<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">`);
		_fh.writeln(`<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css"></head>`);
		_fh.writeln(`<body role="document"><div class="container">`);
	}

	override void write(Record rec)
	{
		string names="", values="";

		// write record name & description
		_fh.writefln(`<h2><span class="label label-primary">%s - %s</span></h2>`,
					rec.name, rec.description);

		// write fields as a HTML table
		_fh.write(`<table class="table table-striped">`);
		foreach (Field f; rec)
		{
			names ~= "<th>" ~ f.name ~ "</th>";
			values ~= "<td>" ~ f.value ~ "</td>";
		}
		_fh.writefln("<thead><tr>%s</tr></thead>", names);
		_fh.writefln("<tbody><tr>%s</tr></tbody>", values);

		_fh.write("</table>");
	}

	// end up HTML tags
	override void close()
	{
		_fh.writeln("</div></body></html>");
		_fh.close();
	}
}
