import std.stdio;
import std.file;
import std.string;
import std.getopt;
import std.algorithm;
import std.datetime;
import std.range;
import std.conv;
import std.exception;
import std.path;

import rbf.field;
import rbf.record;
import rbf.layout;

string inputLayoutFileName;			/// input file layout
enum Format {html, xml, cstruct};		/// output format HTML, ...
Format outputFormat;
bool bCheckLayout;							/// if true, try to validate layouy by checking length
bool stdOutput;									/// if true, print to standard output instead of file

int main(string[] argv)
{
	// check args
	if (argv.length == 1) {
		writeln(r"
Convert XML layout file to other formats.

Usage: layoutconv -l xmlfile -o [html,xml,cstruct] [-O] [-c]

where:

-O	: write to stdout instead of a file
-c  : valide layout first


");
		return 1;
	}

	try {
		// get command line arguments
		getopt(argv,
			std.getopt.config.caseSensitive,
			std.getopt.config.required,
			"l", &inputLayoutFileName,
			"o", &outputFormat,
			"O", &stdOutput,
			"c", &bCheckLayout
		);
	}
	catch (Exception e) {
		stderr.writefln("error: %s", e.msg);
		return 1;
	}

	// define new layout and validate it if requested
	auto layout = new Layout(inputLayoutFileName);
	if (bCheckLayout) layout.validate;

	// build output file name
	File outputHandle = (stdOutput) ? stdout :
		File(baseName(inputLayoutFileName) ~ "." ~ to!string(outputFormat), "w");

	// depending on output wnated format, call appropriate function
	final switch(outputFormat)
	{
		case outputFormat.html:
			layout2html(outputHandle, layout);
			break;
		case outputFormat.xml:
			break;
		case outputFormat.cstruct:
			break;
	}

	// ok
	return 0;
}

// write out HTML table from XML Layout
void layout2html(File html, Layout layout) {

	// write out HTML header (uses bootstrap css framework)
	html.writeln(`<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">`);
	html.writeln(`<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css"></head>`);
	html.writeln(`<style>@media print { h2 {page-break-before: always;} }</style>`);
	html.writeln(`<body role="document"><div class="container theme-showcase" role="main">`);
	html.writefln(`<div class="jumbotron"><h1 class="text-center">%s (%s)</h1></div>`,
			layout.meta.description, layout.meta.layoutVersion);
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
