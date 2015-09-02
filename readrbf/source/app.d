import std.stdio;
import std.file;
import std.string;
import std.getopt;
import std.algorithm;
import std.datetime;
import std.range;

import rbf.field;
import rbf.record;
import rbf.format;
import rbf.reader;
import rbf.writer;
import rbf.conf;
import rbf.args;

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
	auto config = new Config();

	// manage arguments passed from the command line
	auto opts = new CommandLineOption(argv);

  // create new reader according to what is passed in the command
	// line and the configuration found in JSON properties file
	auto reader = reader(opts.inputFileName, config[opts.inputFormat]);

	// create new writer to generate outputFileName matching the outputFormat
	auto writer = writer(opts.outputFileName, opts.outputFormat);

	// in case of HOT files, specifiy our modifier
	// HOT files used the overpunch characters (some alphabetical chars matching
	// digits (?!))
	if (canFind(opts.inputFormat,"hot")) {
		reader.register_mapper = &overpunch.overpunch;
	}


	/*
	if (opts.conditionFile != "")
	{
		conditions = reader.readCondition(opts.conditionFile);
		writeln(conditions);
	}
	*/

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

		// ask for a restriction?
		if (opts.isRestriction) {
			// only print out rec if record name is found is the restriction file
			if (rec.name in opts.fieldNames) {
				auto fieldNamesToKeep = opts.fieldNames[rec.name];
				writer.write(rec.fromList(fieldNamesToKeep));
			}
		}
		else
			writer.write(rec);
	}

	// explicitly call close to finish creating file (specially for Excel files)
	writer.close();

	// print out some stats
	auto elapsedtime = Clock.currTime() - starttime;
	writefln("Records read: %d\nElapsed time = %s", nbRecords, elapsedtime);

}
