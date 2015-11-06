import std.stdio;
import std.file;
import std.string;
import std.getopt;
import std.algorithm;
import std.datetime;
import std.range;
import std.conv;
import std.path;
import std.traits;

import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.recordfilter;
import rbf.layout;
import rbf.reader;
import rbf.writers.writer;
import rbf.config;

import args;

int main(string[] argv)
{
	// number of records read
	auto nbReadRecords = 0;
	auto nbWrittenRecords = 0;


	string[] conditions;

	// need to known how much time spent
	auto starttime = Clock.currTime();

	try {

		// read XML properties from rbf.xml file
		auto settings = new Setting();

		// manage arguments passed from the command line
		auto opts = CommandLineOption(argv);

		// check output formats
		if (opts.outputFormat !in settings.outputDir) {
			throw new Exception(
				"error: output format should be in the following list: %s".
						format(settings.outputDir.names));
		}

		// define new layout corresponding to the requested layout
		auto layout = new Layout(settings.layoutDir[opts.inputLayout].file);

		// layout syntax validation requested
		if (opts.bCheckLayout) {
			layout.validate;
		}

		// need to get rid of some fields ?
		if (opts.isFieldFilterFileSet) {
			// only keep specified fields
			layout.keepOnly(opts.filteredFields, "\n");
		}
		if (opts.isFieldFilterSet) {
			// only keep specified fields
			layout.keepOnly(opts.filteredFields, ";");
		}

		// create new reader according to what is passed in the command
		// line and the configuration found in JSON properties file
		auto reader = new Reader(opts.inputFileName, layout);

		// grep lines?
		if (opts.lineFilter != "") {
			reader.lineRegexPattern = opts.lineFilter;
		}

		// if verbose option is requested, print out what's possible
		if (opts.bVerbose) {
			// print out field type meta info
			printMembers!(LayoutMeta)(layout.meta);
			stderr.writeln;
			foreach (t; layout.ftype) {
				printMembers!(FieldTypeMeta)(t.meta);
				stderr.writeln;
			}
			printMembers!(CommandLineOption)(opts);
			stderr.writeln;
			printMembers!(OutputFeature)(settings.outputDir[opts.outputFormat]);
			stderr.writeln;

            // print out repeated fields if any
            if (opts.bBreakRecord)
            {
                foreach(r; layout) { 
                    if (r.meta.repeatingPattern.length != 0) {
                        stderr.writefln("\nRecord %s", r.name);
                        foreach(rp; r.meta.repeatingPattern) {
                            stderr.writefln("\tRepeating pattern: %s", rp);
                        }
                        foreach(sr; r.meta.subRecord) {
                            stderr.write("\t");
                            sr.each!(f => stderr.writef("%s(%d)-", f.name, f.context.index)); 
                            stderr.writeln();
                        }
                    }
                }
            }
		}

        // re-index each field index
        layout.each!(r => r.recalculateIndex);

        // get alternate names
        layout.each!(r => r.buildAlternateNames);

		// create new writer to generate outputFileName matching the outputFormat
		Writer writer;
		auto outputFileName = buildNormalizedPath(
				settings.outputDir[opts.outputFormat].outputDir,
				opts.outputFileName
		);

		auto output = (opts.stdOutput) ? "" :outputFileName;
		writer = writerFactory(output, opts.outputFormat, layout);

		// set writer features read in config and process preliminary steps
		writer.outputFeature = settings.outputDir[opts.outputFormat];
		writer.prepare(layout);

		// break records?
		if (opts.bBreakRecord)
		{
			layout.each!(r => r.identifyRepeatedFields);
			foreach (r; layout) {
				//writefln("%s:%s", r.name, r.meta.repeatingPattern);
				if (r.meta.repeatingPattern.length != 0)
                    r.meta.repeatingPattern.each!(rp => r.findRepeatedFields(rp));
//					r.findRepeatedFields(r.meta.repeatingPattern[0]);
			}
		}

		// now loop for each record in the file
		foreach (rec; reader)
		{
			// if samples is set, break if record count is reached
			if (opts.samples != 0 && nbReadRecords >= opts.samples) break;

			// record read is increasing
			nbReadRecords++;

			// do we filter out records?
			if (opts.isRecordFilterFileSet || opts.isRecordFilterSet)
			{
				if (!rec.matchRecordFilter(opts.filteredRecords)) continue;
			}

            // don't want a progress bar?
            if (opts.bProgressBar && nbReadRecords % 1000 == 0)
            {
                if (reader.nbRecords != 0)
                    stderr.writef("%d/%d records read so far (%.0f %%)\r",
                            nbReadRecords, reader.nbRecords, to!float(nbReadRecords)/reader.nbRecords*100);
                else
                    stderr.writef("%d lines read so far\r",nbReadRecords);
            }

			// don't want to write? Just loop
			if (opts.bJustRead) continue;

			// use our writer to generate the file
			writer.write(rec);
			nbWrittenRecords++;

			// write sub records if any
			if (opts.bBreakRecord)
			{
				foreach(subRec; rec.meta.subRecord)
				{
					writer.write(subRec);
                    //subRec.each!(f => writef("%s-(%s)",f.name, f.value));
                    //writeln();
				}
			}
		}

		// explicitly call close to finish creating file (specially for Excel files)
		writer.close();

		// print out some stats
		auto elapsedtime = Clock.currTime() - starttime;

		stderr.writefln("\nLines: %d read, records: %d read, %d written\nElapsed time = %s",
			reader.nbLinesRead, nbReadRecords, nbWrittenRecords, elapsedtime);

		if (!opts.bJustRead)
				stderr.writefln("Created file %s, size = %d bytes",
								opts.outputFileName, getSize(opts.outputFileName));
	}
	catch (Exception e) {
		stderr.writeln(e.msg);
		return 1;
	}

	// return code to OS
	return 0;

}
