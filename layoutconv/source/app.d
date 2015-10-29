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
import std.regex;

import rbf.field;
import rbf.record;
import rbf.layout;

string inputLayoutFileName;			/// input file layout
enum Format {html, xml, cstruct, csv};		/// output format HTML, ...
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

-O  : write to stdout instead of a file
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
		case outputFormat.csv:
			layout2csv(outputHandle, layout);
			break;
	}


	layout[argv[1]].findRepeatingPattern;
	auto p = layout[argv[1]].meta.repeatingPattern;
	foreach (l; p)
	{
		writeln(layout[argv[1]].matchFieldList(l));
	}


	/*foreach (rec; &layout.sorted) {
		writeln("trying record: ", rec.name);
		writeln(rec.findRepeatingPattern);
	}*/

	// ok
	return 0;
}

// write out layout as a CSV-list of records and fields
void explore(Layout layout, string recName) {

	// list of records (sorted)
	auto rec = layout[recName];
	//
	// auto list = rec[].filter!(f => rec.count(f.name) > 1);
	//
	//
	// // foreach (f; list) {
	// // 	auto i = f.index;
	// // 	if
	// //
	// // }
	//
	// writeln(recName,":");
	// foreach (f; list) {
	// 	auto count = rec.count(f.name);
	// 	writef("%s%d(%s-%d): ", f.name, f.context.index, f.name, count);
	// 	if (count > 1)
	// 		rec[f.name].each!(f => writef("%s%d ", f.name, f.context.index));
	// 	writeln();
	// }

	auto fields = rec.names;
	string[] sorted_fields = array(sort!("a < b")(rec.names));
	auto uniqueFields = array(fields.uniq);
	//writeln(uniqueFields);
	writefln("fields = %s", fields);

	string s;
	foreach(f; rec) {
		auto i = rec[f.name][0].context.index;
		s ~= "(%d)".format(i);
	}

	auto pattern = ctRegex!(r"((\(\d+\))+?)\1+");

	auto match = matchAll(s, pattern);
	//writeln(match);
	foreach (m; match) {
		writeln(m);
		auto result = matchAll(m[1], r"\((\d+)\)");
		auto a = array(result.map!(r => rec[to!int(r[1])].name));
		writeln(a);
		rec.matchFieldList(a);
	}


/*
	// assign a key to each unique field
	int i = 32;
	char[string] map1;
	string[char] map2;
	foreach (f; uniqueFields) {
		auto c = to!char(i++);
		map1[f] = c;
		map2[c] = f;
	}
	writeln(map1);
	writeln(map2);
	//
	string matchable = 	array(fields.map!(f => map1[f]));
	//auto matchable = s.join;
	writeln(matchable);

	auto pattern = ctRegex!(r"(.+?)\1+");

	auto match = matchAll(matchable, pattern);
	//writeln(match);
	foreach (m; match) {
		string[] s;
		m[1].each!(c => s ~= map2[c]);
		writeln(s);
	}*/

}







// write out layout as a CSV-list of records and fields
void layout2csv(File output, Layout layout) {
	// list of records (sorted)
	foreach (rec; &layout.sorted) {
		output.write(rec.name, ";");
		output.writeln(rec.names.join(';'));
	}
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
			html.writefln(`<td>%s</td>`, field.context.offset+1);
			html.writeln(`</tr>`);

		}
		html.writeln(`</table>`);
	}

	//writefln("Records read: %d\nElapsed time = %s", nbRecords, elapsedtime);
	// closing HTML
	html.writeln(`</div></div></body></html>`);

}
