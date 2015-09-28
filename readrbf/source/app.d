import std.stdio;
import std.file;
import std.string;
import std.getopt;
import std.algorithm;
import std.datetime;
import std.range;
import std.conv;

import rbf.field;
import rbf.record;
import rbf.recordfilter;
import rbf.layout;
import rbf.reader;
import rbf.writers.writer;

import overpunch;
import args;
import config;


int main(string[] argv)
{
	// number of records read
	auto nbReadRecords = 0;
	auto nbWrittenRecords = 0;


	string[] conditions;

	// need to known how much time spent
	auto starttime = Clock.currTime();

	//
	try {

		// read JSON properties from rbf.json file located in:
		// ~/.rbf for Linux
		// %APPDATA%/local/rbf for Windows
		auto settings = new Setting();

		// manage arguments passed from the command line
		writeln(argv);
		auto opts = new CommandLineOption(argv);

		// define new layout corresponding to the requested layout
		auto layout = new Layout(settings[opts.inputLayout].xmlFile);

		// syntax validation requested
		if (opts.checkLayout) {
			layout.validate;
		}

		// need to get rid of some records?
		if (opts.isFieldFilterSet) {
			// only keep specified fields
			layout.keepOnly(opts.filteredFields);
		}

		// if a record filter is set, check if field names belong to layout
		if (opts.isRecordFilterSet) {
			foreach (RecordClause c; opts.filteredRecords) {
				if (c.fieldName !in layout) {
					throw new Exception("error: field name %s not in layout".format(c.fieldName));
				}
			}
		}

		// create new reader according to what is passed in the command
		// line and the configuration found in JSON properties file
		auto reader = new Reader(opts.inputFileName, layout,	settings[opts.inputLayout].mapper);

		// in case of HOT files, specifiy our modifier
		// HOT files used the overpunch characters (some alphabetical chars matching
		// digits (?!))
		if (settings[opts.inputLayout].layoutType == "HOT") {
			reader.recordTransformer = &overpunch.overpunch;
		}

		// do we want to ignore some lines?
		if (!settings[opts.inputLayout].ignoreRecord.empty) {
			reader.ignoreRegexPattern = settings[opts.inputLayout].ignoreRecord;
		}

		// do we want to get rid of some fields for all records?
		if (settings[opts.inputLayout].skipField != "") {
			auto fieldList = settings[opts.inputLayout].skipField.split(",");
			fieldList = array(fieldList.map!(s => s.strip));
			layout.removeFromAllRecords(fieldList);
			writefln("info: skipping fields %s", fieldList);
		}

		// create new writer to generate outputFileName matching the outputFormat
		auto writer = writerFactory(opts.outputFileName, opts.outputFormat, reader.layout);

		// in case of Excel output format, set zipper
		if (opts.outputFormat == "xlsx") {
			writer.zipper = settings.zipper;
		}

		// if verbose option is requested, print out what's possible
		if (opts.verbose) {
			opts.printOptions;
		}

		// stuff to correctly display a progress bar
		immutable termWidth = 78;
		//auto inputFileSize = getSize(opts.inputFileName);
		char[termWidth] progressBar = ' ';
		//auto chunkSize = to!ulong(inputFileSize / termWidth);

		//writef("\n%s", progressBar);
		writeln();

		// now loop for each record in the file
		foreach (rec; reader)
		{
			// if progress bar, print out moving cursor
			if (opts.progressBar && nbReadRecords % 4096 == 0) {
				writef("read %.0f %% of %u bytes\r",
							reader.currentReadSize/to!float(reader.inputFileSize)*100.0, reader.inputFileSize);
			}


				// if samples is set, break if record count is reached
			if (opts.samples != 0 && nbReadRecords >= opts.samples) break;

			// record read is increasing
			nbReadRecords++;

			// do we filter out records?
			if (opts.isRecordFilterSet) {
				if (!rec.matchRecordFilter(opts.filteredRecords))
					continue;
			}

			// don't want to write? Just loop
			if (opts.dontWrite) continue;

			// use our writer to generate the file
			writer.write(rec);
			nbWrittenRecords++;
		}

		// explicitly call close to finish creating file (specially for Excel files)
		writer.close();

		// print out some stats
		auto elapsedtime = Clock.currTime() - starttime;
		writefln("\nRecords: %d read, %d written\nElapsed time = %s",
			nbReadRecords, nbWrittenRecords, elapsedtime);
		if (!opts.dontWrite)
				writefln("Created file %s, size = %d bytes",
								opts.outputFileName, getSize(opts.outputFileName));
	}
	catch (Exception e) {
		writeln(e.msg);
		return 1;
	}

	// return code to OS
	return 0;

}
