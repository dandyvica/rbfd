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

	// define new layout
	auto layout = new Layout(settings[opts.inputFormat].xmlFile);

	// ask for a restriction?
	if (opts.isRestriction) {
		// prune each record depending on what is requested
		layout.prune(opts.fieldNames);
	}

  // create new reader according to what is passed in the command
	// line and the configuration found in JSON properties file
	auto reader = new Reader(
		opts.inputFileName, layout,	settings[opts.inputFormat].mapper
	);

	// in case of HOT files, specifiy our modifier
	// HOT files used the overpunch characters (some alphabetical chars matching
	// digits (?!))
	if (canFind(opts.inputFormat,"hot")) {
		reader.register_mapper = &overpunch.overpunch;
	}



//	writeln(reader.layout); writeln(opts.fieldNames);
//	core.stdc.stdlib.exit(0);

	// create new writer to generate outputFileName matching the outputFormat
	auto writer = writer(opts.outputFileName, opts.outputFormat, reader.layout);

	// now loop for each record in the file
	foreach (rec; reader)
	{
		// record read is increasing
		nbRecords++;

		// do we filter out records?
		if (opts.isFilter) {
			if (!rec.matchFilter(opts.filter))
				continue;
		}

		// use our writer to generate the file
		writer.write(rec);
	}

	// explicitly call close to finish creating file (specially for Excel files)
	writer.close();

	// print out some stats
	auto elapsedtime = Clock.currTime() - starttime;
	writefln("Records read: %d\nElapsed time = %s", nbRecords, elapsedtime);

}
