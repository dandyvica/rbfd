module rbf.convert;
pragma(msg, "========> Compiling module ", __MODULE__);

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

import rbf.config;
import rbf.field;
import rbf.record;
import rbf.layout;

string inputLayoutFileName;		        	/// input file layout
string inputTemplate;                       /// template string to fill
enum Format {html, xml, include, csv, temp};		/// output format HTML, ...
Format outputFormat;

void convertLayout(string inputLayoutFileName, Format outputFormat, string inputTemplate)
{
    // define new layout and validate it if requested
    auto layout = new Layout(inputLayoutFileName);

    // send to stdout
    File outputHandle = stdout;

    // depending on output wnated format, call appropriate function
    final switch(outputFormat)
    {
        case outputFormat.html:
            layout2html(outputHandle, layout);
            break;
        case outputFormat.xml:
            break;
        case outputFormat.include:
            // this is necessary to use alternate name because names can be duplicated
            layout.each!(r => r.buildAlternateNames);
            layout2cstruct(outputHandle, layout);
            break;
        case outputFormat.csv:
            layout2csv(outputHandle, layout);
            break;
        case outputFormat.temp:
            layout2temp(outputHandle, inputTemplate, layout);
            break;
    }
}

// write out layout as a CSV-list of records and fields
void layout2csv(File output, Layout layout) 
{
	// list of records (sorted)
	foreach (rec; &layout.sorted) 
    {
		output.write(rec.name, ";");
		output.writeln(rec.names.join(';'));
	}
}

// write out layout as a template string
void layout2temp(File output, string inputTemplate, Layout layout) 
{
    // output string when replacing tags
    string outputString;

	// list of records (sorted)
	foreach (rec; &layout.sorted) 
    {
        foreach (f; rec) 
        {

            outputString = inputTemplate.replace("recname", rec.name)
                .replace("recdesc", rec.meta.description)
                .replace("fname", f.name)
                .replace("faltname", f.context.alternateName)
                .replace("fdesc", f.description)
                .replace("flength", to!string(f.length))
                .replace("ftype", f.type.meta.stringType)
                .replace("foffset", to!string(f.context.offset+1))
                .replace("findex", to!string(f.context.index+1))
                ;
                        output.writeln(outputString);
        }
	}
}

// write out HTML table from XML Layout
void layout2html(File html, Layout layout) 
{

	// write out HTML header (uses bootstrap css framework)
	html.writeln(`<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">`);
	html.writeln(`<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css"></head>`);
	html.writeln(`<style>@media print { h2 {page-break-before: always;} }</style>`);
	html.writeln(`<body role="document"><div class="container theme-showcase" role="main">`);
	html.writefln(`<div class="jumbotron"><h1 class="text-center">%s (%s)</h1></div>`,
			layout.meta.description, layout.meta.layoutVersion);
	html.writeln(`<div class="container">`);

	// loop on each record (sorted)
	foreach (rec; layout) 
    {
		// loop on each
		//auto rec = fmt[recName];

		// record description
		html.writefln(`<h2><span class="label label-primary">%s-%s-%d</span></h2>`,
			rec.name, rec.meta.description, rec.length);

		// fields description
		html.writeln(`<table class="table table-striped">`);
		html.writeln(`<thead><tr><th>#</th><th>Field name</th><th>Description</th>`);
		html.writeln(`<th>Length</th><th>Offset</th></tr></thead>`);

		// loop on each field to print out description
		auto i = 1;
		foreach (field; rec) 
        {
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

// write out XML layout structure as as C-union
void layout2cstruct(File output, Layout layout) 
{
    // inclusion watchguard
    output.writefln("#ifndef %s_H", layout.meta.name.toUpper); 
    output.writefln("#define %s_H", layout.meta.name.toUpper); 
    output.writeln;

    // print out defines for each record name
	foreach (rec; &layout.sorted) 
    {
        output.writefln(`#define RECORD_%s "%s"       // %s`, rec.name, rec.name, rec.meta.description);
    }
    output.writeln;

    // each record is converted as a C structure
	foreach (rec; &layout.sorted) 
    {
        // structure header
		output.writefln("// %s", rec.meta.description);
		output.writefln("typedef struct RECORD_%s_T {", rec.name);

        // each field is a structure member
        foreach (f; rec)
        {
    		output.writefln("\tchar %s[%d];\t\t// %s", f.context.alternateName, f.length, f.description);
        }

        // end structure
		output.writefln("} RECORD_%s_T;", rec.name);
        output.writeln;
	}

    // now write union
	output.writefln("typedef union %s_T {", layout.meta.name.toUpper);
	foreach (rec; &layout.sorted) 
    {
        output.writefln("\tRECORD_%s_T rec_%s; // %s", rec.name, rec.name, rec.meta.description);
    }
	output.writefln("} %s_T;", layout.meta.name.toUpper);
    output.writeln;
    output.writefln("#endif"); 

}
