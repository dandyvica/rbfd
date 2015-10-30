module rbf.writers.htmlwriter;
pragma(msg, "========> Compiling module ", __MODULE__);

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
import rbf.config;
import rbf.writers.writer;

immutable formatter = `format("<%s>%s</%s>",a,b,a)`;
alias htmlRowBuilder = binaryFun!(formatter);

/*********************************************
 * each record is displayed as an HTML table
 */
class HTMLWriter : Writer {

	this(in string outputFileName)
	{
		super(outputFileName);
	}

	override void prepare() {
		// bootstrap header
		_fh.writeln(`<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">`);
		_fh.writeln(`<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css"></head>`);
		_fh.writeln(`<body role="document"><div class="container">`);
	}

	// write out record depending on orientation
	override void write(Record rec)
	{
		if (outputFeature.orientation == Orientation.horizontal)
			_writeH(rec);
		else
			_writeV(rec);
	}

	// end up HTML tags
	override void close()
	{
		_fh.writeln("</table></div></body></html>");
		Writer.close();
	}

private:
	string _buildHTMLDataRow(Record rec) {
    return array(rec.fieldValues.map!(f => htmlRowBuilder("td",f))).join("");
	}

	// write out data with values in row
	void _writeV(Record rec) {
		// write fields as a HTML table
		// start a new HTML table

    // write record name & description
		_fh.writefln(`</table><h2><span class="label label-primary">%s - %s</span></h2>`,
					rec.meta.name, rec.meta.description);

		// gracefully end previous table and start a new HTML table
		_fh.write(`<table class="table table-striped">`);

		// write out table header
		_fh.write(`<tr><th>Index</th><th>Field</th><th>Description</th><th>Length</th><th>Type</th><th>Value</th></tr>`);
		foreach (f; rec) {
			_fh.write(
				`<tr><th>%s</th><th>%s</th><th>%s</th><th>%s</th><th>%s</th><th>%s</th></tr>`.
						format(f.context.index+1, f.name, f.description, f.length, f.type.meta.name, f.value)
			);
		}

		// gracefully ends table
		_fh.write(`</table>`);

	}

	// write out data with values in columns
	void _writeH(Record rec) {
		// write fields as a HTML table
		// start a new HTML table
		if (_previousRecordName != rec.name) {

			// first record is a special case
			if (_previousRecordName != "") {
				_fh.writefln("</table>");
			}

      // write record name & description
  		_fh.writefln(`</table><h2><span class="label label-primary">%s - %s</span></h2>`,
  					rec.name, rec.meta.description);

			// gracefully end previous table and start a new HTML table
			_fh.write(`<table class="table table-striped">`);

			// print out headers
			auto headers = array(rec.fieldNames.map!(f => htmlRowBuilder("th",f))).join("");
			_fh.writefln("<thead><tr>%s</tr></thead>", headers);

			// and field descriptions
			auto desc = array(rec.fieldDescriptions.map!(f => htmlRowBuilder("th",f))).join("");
			_fh.writefln("<tr>%s</tr>", desc);

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

}
///
unittest {

	writeln("========> testing ", __FILE__);

	import rbf.layout;
	import rbf.reader;

	auto layout = new Layout("./test/world_data.xml");
	auto reader = new Reader("./test/world.data", layout);

	auto writer = writerFactory("./test/world_data.html", "html", layout);
	writer.prepare;
	foreach (rec; reader) { writer.write(rec); }

	writer.close();
}
