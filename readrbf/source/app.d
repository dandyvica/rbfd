import std.stdio;
import std.file;
import std.string;
import std.getopt;
import std.algorithm;
import std.datetime;
import std.range;

import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.reader;
import rbf.writers.writer;
import rbf.conf;
import rbf.args;
import rbf.config;

import overpunch;


void main(string[] argv)
{
	// number of records read
	auto nbRecords = 1;


	string[] conditions;

	// need to known how much time spent
	auto starttime = Clock.currTime();

	// read JSON properties from rbf.json file located in:
	// ~/.rbf for Linux
	// %APPDATA%/local/rbf for Windows
	configSettings = new Config();
	auto settings = new Setting();

	// manage arguments passed from the command line
	auto opts = new CommandLineOption(argv);

	// define new layout corresponding to the requested layout
	auto layout = new Layout(settings[opts.inputLayout].xmlFile);

	// need to get rid of some records?
	if (opts.isFieldFilterSet) {
		// prune each record off of field names
		layout.prunePerRecords(opts.filteredFields);
	}

  // create new reader according to what is passed in the command
	// line and the configuration found in JSON properties file
	auto reader = new Reader(
		opts.inputFileName, layout,	settings[opts.inputLayout].mapper
	);

	// in case of HOT files, specifiy our modifier
	// HOT files used the overpunch characters (some alphabetical chars matching
	// digits (?!))
	if (settings[opts.inputLayout].layoutType == "HOT") {
		reader.register_mapper = &overpunch.overpunch;
	}

	// do we want to ignore some lines?
	if (!settings[opts.inputLayout].ignorePattern.empty) {
		reader.ignoreRegexPattern = settings[opts.inputLayout].ignorePattern;
	}

	// do we want to get rid of some fields for all records?
	if (settings[opts.inputLayout].skipField != "") {
		auto fieldList = settings[opts.inputLayout].skipField.split(",");
		fieldList = array(fieldList.map!(s => s.strip));
		layout.pruneAll(fieldList);
	}

//	writeln(reader.layout); writeln(opts.fieldNames);
//	core.stdc.stdlib.exit(0);

	// create new writer to generate outputFileName matching the outputFormat
	auto writer = writer(opts.outputFileName, opts.outputFormat, reader.layout);

	// if verbose is requested, print out what's possible
	if (opts.verbose) {
		opts.printOptions;
	}

	// now loop for each record in the file
	foreach (rec; reader)
	{
 		// if samples is set, break is count is over
		if (opts.samples != 0 && nbRecords > opts.samples) break;

		// record read is increasing
		nbRecords++;

		// do we filter out records?
		if (opts.isRecordFilterSet) {
			if (!rec.matchFilter(opts.filteredRecords))
				continue;
		}

		// use our writer to generate the file
		writer.write(rec);
	}

	// explicitly call close to finish creating file (specially for Excel files)
	writer.close();

	// print out some stats
	auto elapsedtime = Clock.currTime() - starttime;
	writefln("\nCreated file %s, size = %d",
		opts.outputFileName, getSize(opts.outputFileName));
	writefln("Records read: %d\nElapsed time = %s", nbRecords, elapsedtime);

}
