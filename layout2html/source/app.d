import std.stdio;
import std.file;
import std.string;
import std.getopt;
import std.algorithm;
import std.datetime;
import std.range;
import std.conv;
import std.exception;

import rbf.field;
import rbf.record;
import rbf.layout;


int main(string[] argv)
{
	// check args
	if (argv.length == 1) {
		writeln("\nConvert XML layout file to HTML file.\n\nUsage:\tlayout2html xmlfile [output_file]\n");
		return 1;
	}


	auto format = argv[1];

	// read JSON properties from rbf.json file located in:
	// ~/.rbf for Linux
	// %APPDATA%/local/rbf for Windows

	try {
		// output HTML file name
		File html;
		if (argv.length == 3)
			html = File(argv[2], "w");
		else
			html = stdout;

		// define new structure
		auto layout = new Layout(argv[1]);

		// validate layout
		layout.validate;
/*
		// checking first XML file compliance if layou length was specified
		if (layout.length != 0) {
			foreach (rec; layout) {
				enforce(rec.length == layout.length, "Record %s length is incorrect (%d != %d)".
					format(rec.name, rec.length, layout.length));
			}
		}
*/

		// write out HTML header (uses bootstrap css framework)
		html.writeln(`<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">`);
		html.writeln(`<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css"></head>`);
		html.writeln(`<style>@media print { h2 {page-break-before: always;} }</style>`);
		html.writeln(`<body role="document"><div class="container theme-showcase" role="main">`);
		html.writefln(`<div class="jumbotron"><h1 class="text-center">%s (%s)</h1></div>`,
				layout.description, layout.layoutVersion);
		html.writeln(`<div class="container">`);

	  // loop on each record (sorted)
		foreach (rec; layout) {
			// loop on each
			//auto rec = fmt[recName];

			// record description
			html.writefln(`<h2><span class="label label-primary">%s-%s</span></h2>`,
				rec.name, rec.description);

			// fields description
			html.writeln(`<table class="table table-striped">`);
			html.writeln(`<thead><tr><th>#</th><th>Field name</th><th>Description</th>`);
			html.writeln(`<th>Length</th><th>Offset</th></tr></thead>`);

			// loop on each field to print out description
			auto i = 1;
			foreach (field; rec) {
				html.writeln(`<tr>`);
				html.writefln(`<td>%s</td>`,i++);
				html.writefln(`<td><strong>%s</strong></td>`,field.name);
				html.writefln(`<td>%s</td>`, field.description);
				html.writefln(`<td>%s</td>`, field.length);
				html.writefln(`<td>%s</td>`, field.offset+1);
				html.writeln(`</tr>`);

			}
			html.writeln(`</table>`);
		}

		//writefln("Records read: %d\nElapsed time = %s", nbRecords, elapsedtime);
		// closing HTML
		html.writeln(`</div></div></body></html>`);
	}
	catch (Exception e) {
		writeln(e.msg);
		return 1;
	}

	// ok
	return 0;

}
/**
 * return a string of the XML representation of Record
 */
// string toXML() {
// 	auto xml = `<record name="%s" description=""%s">`.format(meta.name, meta.description);
// 	xml ~= join(array(this[].map!(e => "\t" ~ e.toXML)), "\n");
// 	xml ~= "</record>";
//
// 	return xml;
// }
