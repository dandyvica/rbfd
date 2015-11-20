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
import std.concurrency;

import rbf.errormsg;
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
	auto nbMatchedRecords = 0;

    //auto tid = spawn(&spawnedFunction);

    //---------------------------------------------------------------------------------
	// need to known how much time spent
    //---------------------------------------------------------------------------------
	auto starttime = Clock.currTime();

	try 
    {

        //---------------------------------------------------------------------------------
		// read XML properties from rbf.xml file
        //---------------------------------------------------------------------------------
		auto settings = new Setting();

        //---------------------------------------------------------------------------------
		// manage arguments passed from the command line
        //---------------------------------------------------------------------------------
		auto opts = CommandLineOption(argv);

        //---------------------------------------------------------------------------------
		// check output formats
        //---------------------------------------------------------------------------------
		if (to!string(opts.outputFormat) !in settings.outputDir) 
        {
			throw new Exception(
				"fatal: output format should be in the following list: %s".
						format(settings.outputDir.names));
		}

        //---------------------------------------------------------------------------------
		// define new layout corresponding to the requested layout
        //---------------------------------------------------------------------------------
		auto layout = new Layout(settings.layoutDir[opts.inputLayout].file);

        //---------------------------------------------------------------------------------
		// layout syntax validation requested
        //---------------------------------------------------------------------------------
		if (opts.bCheckLayout) 
        {
			layout.validate;
		}

        //---------------------------------------------------------------------------------
		// need to get rid of some fields ?
        //---------------------------------------------------------------------------------
		if (opts.isFieldFilterFileSet) 
        {
            //---------------------------------------------------------------------------------
			// only keep specified fields
            //---------------------------------------------------------------------------------
			layout.keepOnly(opts.filteredFields, "\n");
            log.log(LogLevel.INFO, MSG026, layout.size);
		}
        // list of records/fields given from the command line
		if (opts.isFieldFilterSet) 
        {
            //---------------------------------------------------------------------------------
			// only keep specified fields
            //---------------------------------------------------------------------------------
			layout.keepOnly(opts.filteredFields, ";");
            log.log(LogLevel.INFO, MSG026, layout.size);
		}

        //---------------------------------------------------------------------------------
		// create new reader according to what is passed in the command
		// line and the configuration found in JSON properties file
        //---------------------------------------------------------------------------------
		auto reader = new Reader(opts.inputFileName, layout);
        log.log(LogLevel.INFO, MSG016, opts.inputFileName, reader.inputFileSize);

        //---------------------------------------------------------------------------------
		// check field patterns?
        //---------------------------------------------------------------------------------
        reader.checkPattern = opts.bCheckPattern;

        //---------------------------------------------------------------------------------
		// grep lines?
        //---------------------------------------------------------------------------------
		if (opts.lineFilter != "") 
        {
			reader.lineRegexPattern = opts.lineFilter;
		}

        //---------------------------------------------------------------------------------
		// verify record filter arguments: if field name is not found in layout, stop
        //---------------------------------------------------------------------------------
        if (opts.isRecordFilterFileSet || opts.isRecordFilterSet)
        {
            foreach(rf; opts.filteredRecords)
            {
                if (!layout.isFieldInLayout(rf.fieldName))
                {
                    throw new Exception(MSG024.format(rf.fieldName));
                }
            }
        }

        //---------------------------------------------------------------------------------
		// if verbose option is requested, print out what's possible
        //---------------------------------------------------------------------------------
		if (opts.bVerbose) 
        {
            //---------------------------------------------------------------------------------
			// print out field type meta info
            //---------------------------------------------------------------------------------
			printMembers!(LayoutMeta)(layout.meta);
			foreach (t; layout.ftype) 
            {
				printMembers!(FieldTypeMeta)(t.meta);
			}
			printMembers!(CommandLineOption)(opts);
			printMembers!(OutputFeature)(settings.outputDir[opts.outputFormat]);

		}

        //---------------------------------------------------------------------------------
        // re-index each field index
        //---------------------------------------------------------------------------------
        layout.each!(r => r.recalculateIndex);

        //---------------------------------------------------------------------------------
        // build alternate names
        //---------------------------------------------------------------------------------
        layout.each!(r => r.buildAlternateNames);

        //---------------------------------------------------------------------------------
		// create new writer to generate outputFileName matching the outputFormat
        //---------------------------------------------------------------------------------
		Writer writer;
		auto outputFileName = buildNormalizedPath(
				settings.outputDir[opts.outputFormat].outputDir,
				opts.outputFileName
		);

		auto output = (opts.stdOutput) ? "" :outputFileName;
		writer = writerFactory(output, opts.outputFormat, layout);

        //---------------------------------------------------------------------------------
		// set writer features read in config and process preliminary steps
        //---------------------------------------------------------------------------------
		writer.outputFeature = settings.outputDir[opts.outputFormat];
		writer.prepare(layout);

		// break records?
		if (opts.bBreakRecord)
		{
            log.log(LogLevel.INFO, MSG039);
			layout.each!(r => r.identifyRepeatedFields);
			foreach (rec; layout) 
            {
				if (rec.meta.repeatingPattern.length != 0)
                {
                    rec.meta.repeatingPattern.each!(rp => rec.findRepeatedFields(rp));
                    rec.meta.repeatingPattern.each!(rp => log.log(LogLevel.INFO, MSG040, rec.name, rp));
                }
			}
		}

        //---------------------------------------------------------------------------------
		// now loop for each record in the file
        //---------------------------------------------------------------------------------
		foreach (rec; reader)
		{
            //---------------------------------------------------------------------------------
			// record read is increasing
            //---------------------------------------------------------------------------------
			nbReadRecords++;

            //---------------------------------------------------------------------------------
			// if samples is set, break if record count is reached
            //---------------------------------------------------------------------------------
			if (opts.samples != 0 && nbReadRecords > opts.samples) 
            {
                break;
            }

            //---------------------------------------------------------------------------------
            // don't want a progress bar?
            //---------------------------------------------------------------------------------
            if (opts.bProgressBar && nbReadRecords % 1000 == 0)
            {
                if (reader.nbRecords != 0)
                    stderr.writef("info: %d/%d records read so far (%.0f %%), %d matching record filter condition\r",
                            nbReadRecords, reader.nbRecords, to!float(nbReadRecords)/reader.nbRecords*100, nbMatchedRecords);
                else
                    stderr.writef("%d lines read so far\r",nbReadRecords);
            }

            //---------------------------------------------------------------------------------
			// do we filter out records?
            //---------------------------------------------------------------------------------
			if (opts.isRecordFilterFileSet || opts.isRecordFilterSet)
			{
				if (!rec.matchRecordFilter(opts.filteredRecords)) continue;
                nbMatchedRecords++;
			}

            //---------------------------------------------------------------------------------
			// don't want to write? Just loop
            //---------------------------------------------------------------------------------
			if (opts.bJustRead) continue;

            //---------------------------------------------------------------------------------
			// use our writer to generate the file
            //---------------------------------------------------------------------------------
			writer.write(rec);
			nbWrittenRecords++;

            //---------------------------------------------------------------------------------
			// write sub records if any
            //---------------------------------------------------------------------------------
			if (opts.bBreakRecord)
			{
				foreach(subRec; rec.meta.subRecord)
				{
                    // don't write empty records (this might occur for sub records)
                    if (subRec.value == "") continue;
					writer.write(subRec);
				}
			}
		}

        //---------------------------------------------------------------------------------
		// explicitly call close to finish creating file (specially for Excel files)
        //---------------------------------------------------------------------------------
		writer.close();

        //---------------------------------------------------------------------------------
		// print out some stats
        //---------------------------------------------------------------------------------
		auto elapsedtime = Clock.currTime() - starttime;

        stderr.writeln();
		stderr.writefln(MSG014, reader.nbLinesRead, nbReadRecords, nbWrittenRecords);
		//stderr.writefln(MSG015, elapsedtime);
		log.log(LogLevel.INFO, MSG015, elapsedtime);

		if (!opts.bJustRead)
				stderr.writefln(MSG013, opts.outputFileName, getSize(opts.outputFileName));

        //---------------------------------------------------------------------------------
		// and some logs
        //---------------------------------------------------------------------------------
        int seconds;
        elapsedtime.split!"seconds"(seconds);

        if (seconds != 0) log.log(LogLevel.INFO, MSG017, to!float(nbReadRecords/seconds));
	}
	catch (Exception e) 
    {
		stderr.writeln(e.msg);
		return 1;
	}

	// return code to OS
	return 0;

}





// test
void spawnedFunction()
{
    int result=0;

    while (result != 1)
    {
        receive(
                (Field f) { writefln("Received field <%s>", f.name); },
                (string recName) { writefln("Received record <%s>", recName); },
                (int i) { 
                    writefln("Received i=%d, ending thread", i); 
                    result = i;
                },
               );
    }
}
