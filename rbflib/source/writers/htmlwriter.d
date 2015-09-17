module rbf.writers.htmlwriter;

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
import rbf.writers.writer;

immutable formatter = "format(\"<%s>%s</%s>\",a,b,a)";
alias htmlRowBuilder = binaryFun!(formatter);

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
		// write fields as a HTML table
		// start a new HTML table
		if (_previousRecordName != rec.name) {

      // write record name & description
  		_fh.writefln(`<h2><span class="label label-primary">%s - %s</span></h2>`,
  					rec.name, rec.description);

			// start a new HTML table

      // first, gracefully end previous table if any
      if (_previousRecordName == "")
			   _fh.write(`<table class="table table-striped">`);
      else
			   _fh.write(`</table><table class="table table-striped">`);

			// print out headers
			auto headers = array(rec.fieldNames.map!(f => htmlRowBuilder("th",f))).join("");
			_fh.writefln("<thead><tr>%s</tr></thead>", headers);

      // print out first set of data
			_fh.writefln("<tr>%s</tr>", _buildHTMLDataRow(rec));

      // save a new record name
		  _previousRecordName = rec.name;
		}
    // HTML table already started: just add row values
		else
    {
			_fh.writefln("<tr>%s</tr>", _buildHTMLDataRow(rec));
    }

	}

	// end up HTML tags
	override void close()
	{
		_fh.writeln("</table></div></body></html>");
		_fh.close();
	}

private:
	string _buildHTMLDataRow(Record rec) {
    return array(rec.fieldValues.map!(f => htmlRowBuilder("td",f))).join("");
	}

}
