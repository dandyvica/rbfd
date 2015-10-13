module rbf.writers.latexwriter;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;

import rbf.field;
import rbf.record;
import rbf.writers.writer;

/*********************************************
 * in this case, each record is displayed as an ASCII table
 */
class LatexWriter : Writer {

public:

	this(in string outputFileName)
	{
		super(outputFileName);

		// latex standard header
		_fh.writeln(`\documentclass[a4paper,10pt]{article}`);
		_fh.writeln(`\begindocument`);
	}

	override void write(Record rec)
	{
		// // write fields as a Latex table
		// // start a new Latex table
		// if (_previousRecordName != rec.name) {
		//
		// 	// first record is a special case
		// 	if (_previousRecordName != "") {
		// 		_fh.writefln("</table>");
		// 	}
		//
    //   // write record name & description
  	// 	_fh.writefln(`</table><h2><span class="label label-primary">%s - %s</span></h2>`,
  	// 				rec.name, rec.description);
		//
		// 	// gracefully end previous table and start a new HTML table
		// 	_fh.write(`<table class="table table-striped">`);
		//
		// 	// print out headers
		// 	auto headers = array(rec.fieldNames.map!(f => htmlRowBuilder("th",f))).join("");
		// 	_fh.writefln("<thead><tr>%s</tr></thead>", headers);
		//
		// 	// and field descriptions
		// 	auto desc = array(rec.fieldDescriptions.map!(f => htmlRowBuilder("th",f))).join("");
		// 	_fh.writefln("<tr>%s</tr>", desc);
		//
    //   // print out first set of data
		// 	_fh.writefln("<tr>%s</tr>", _buildHTMLDataRow(rec));
		//
    //   // save a new record name
		//   _previousRecordName = rec.name;
		// }
    // // HTML table already started: just add row values
		// else
    // {
		// 	_fh.writefln("<tr>%s</tr>", _buildHTMLDataRow(rec));
    // }
	}

	override void close() {
		_fh.writeln(`\enddocument`);
		Writer.close();
	}

}