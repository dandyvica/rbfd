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
import std.parallelism;

import rbf.errormsg;
import rbf.log;
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.recordfilter;
import rbf.layout;
import rbf.reader;
import rbf.writers.writer;
import rbf.config;
import rbf.stat;

import args;

// constants
immutable chunkSize = 1000;         /// print out message every chunkSize record

int main(string[] argv)
{
	// number of records read
	//auto nbReadRecords    = 0;
	//auto nbWrittenRecords = 0;
	//auto nbMatchedRecords = 0;

    //auto tid = spawn(&spawnedFunction);

    // settings class for storing whole configuration
    Config settings;

    //---------------------------------------------------------------------------------
	// need to known how much time spent
    //---------------------------------------------------------------------------------
	auto starttime = Clock.currTime();

	try 
    {

        //---------------------------------------------------------------------------------
		// manage arguments passed from the command line
        //---------------------------------------------------------------------------------
		auto opts = CommandLineOption(argv);

        //---------------------------------------------------------------------------------
		// configuration file passed as arugment? Use it if neccessary
        //---------------------------------------------------------------------------------
        if (opts.options.cmdlineConfigFile != "")
        {
            settings = new Config(opts.options.cmdlineConfigFile);
        }
        else
        {
		    settings = new Config();
        }

        //---------------------------------------------------------------------------------
		// start logging data
        //---------------------------------------------------------------------------------
        log.info(MSG061, argv);
        log.info(MSG050, totalCPUs);

        //---------------------------------------------------------------------------------
		// output format is an enum but should match the string in rbf.xml config file
        //---------------------------------------------------------------------------------
        auto outputFormat = to!string(opts.options.outputFormat);

        //---------------------------------------------------------------------------------
		// use output file name if given or build it
        //---------------------------------------------------------------------------------
        if (opts.options.givenOutputFileName != "")
        {
            opts.outputFileName = opts.options.givenOutputFileName;
        }
        else
        {
            opts.outputFileName = baseName(opts.options.inputFileName) ~ "." ~ settings.outputDir[outputFormat].outputFileExtension;
        }

        //---------------------------------------------------------------------------------
		// check if œoutput format is valid
        //---------------------------------------------------------------------------------
		if (outputFormat !in settings.outputDir) 
        {
			throw new Exception(MSG058.format(settings.outputDir.names));
		}

        //---------------------------------------------------------------------------------
		// define new layout corresponding to the requested layout given from the command line
        //---------------------------------------------------------------------------------
		auto layout = new Layout(settings.layoutDir[opts.options.inputLayout].file);

        //---------------------------------------------------------------------------------
		// layout syntax validation requested from command line ?
        //---------------------------------------------------------------------------------
		if (opts.options.bCheckLayout) 
        {
			layout.validate;
		}

        //---------------------------------------------------------------------------------
		// use alternate names if requested
        //---------------------------------------------------------------------------------
		if (opts.options.bUseAlternateNames) 
        {
			settings.outputDir[outputFormat].useAlternateName = true;
		}

        //---------------------------------------------------------------------------------
		// need to get rid of some fields ?
        //---------------------------------------------------------------------------------
		if (opts.isFieldFilterFileSet) 
        {
            //---------------------------------------------------------------------------------
			// only keep specified fields
            //---------------------------------------------------------------------------------
			layout.keepOnly(opts.filteredFields, std.ascii.newline);
            log.info(MSG026, layout.size);
		}
        // list of records/fields given from the command line
		if (opts.isFieldFilterSet) 
        {
            //---------------------------------------------------------------------------------
			// only keep specified fields
            //---------------------------------------------------------------------------------
			layout.keepOnly(opts.filteredFields, ";");
            log.info(MSG026, layout.size);
		}

        //---------------------------------------------------------------------------------
		// create new reader according to what is passed in the command
		// line and the configuration found in JSON properties file
        //---------------------------------------------------------------------------------
		auto reader = new Reader(opts.options.inputFileName, layout);
        log.info(MSG016, opts.options.inputFileName, reader.inputFileSize);

        //---------------------------------------------------------------------------------
		// check field patterns?
        //---------------------------------------------------------------------------------
        reader.checkPattern = opts.options.bCheckPattern;

        //---------------------------------------------------------------------------------
		// grep lines?
        //---------------------------------------------------------------------------------
		if (opts.options.lineFilter != "") 
        {
			reader.lineRegexPattern = opts.options.lineFilter;
		}

        //---------------------------------------------------------------------------------
		// if verbose option is requested, print out what's possible
        //---------------------------------------------------------------------------------
		if (opts.options.bVerbose) 
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
			printMembers!(OutputFeature)(settings.outputDir[outputFormat]);
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
        // re-index each field because we might have deleted fields
        //---------------------------------------------------------------------------------
        layout.each!(r => r.recalculateIndex);

        //---------------------------------------------------------------------------------
        // build alternate field names
        //---------------------------------------------------------------------------------
        layout.each!(r => r.buildAlternateNames);

        //---------------------------------------------------------------------------------
		// create new writer to generate outputFileName matching the outputFormat
        //---------------------------------------------------------------------------------
		Writer writer;
		auto outputFileName = buildNormalizedPath(
				settings.outputDir[outputFormat].outputDirectory,
				opts.outputFileName
		);

		auto output = (opts.options.stdOutput) ? "" : outputFileName;
		writer = writerFactory(output, opts.options.outputFormat);

        //---------------------------------------------------------------------------------
		// set writer features read in config and process preliminary steps
        //---------------------------------------------------------------------------------
		writer.outputFeature = settings.outputDir[outputFormat];

        // SQL format adds additonal feature
        if (opts.options.outputFormat == OutputFormat.sql) 
        {
            writer.outputFeature.sqlPreFile  = opts.options.sqlPreFile;
            writer.outputFeature.sqlPostFile = opts.options.sqlPostFile;
        }

        // some writers need preliminary process
		writer.prepare(layout);

        //---------------------------------------------------------------------------------
		// break records?
        //---------------------------------------------------------------------------------
		if (opts.options.bBreakRecord || opts.options.bPrintDuplicatedPattern)
		{
            log.info(MSG039);

            // try to identify those fields which are repeated
			layout.each!(r => r.identifyRepeatedFields);
			foreach (rec; layout) 
            {
				if (rec.meta.repeatingPattern.length != 0)
                {
                    rec.meta.repeatingPattern.each!(rp => rec.findRepeatedFields(rp));
                    rec.meta.repeatingPattern.each!(rp => log.info(MSG040, rec.name, rp));

                    // we just want to print out repeated fields
                    if (opts.options.bPrintDuplicatedPattern)
                    {
                        foreach (sr; rec.meta.subRecord)
                        {
                            writefln("%s: %s", rec.name, join(sr.fieldAlternateNames, ","));
                        }
                        writeln;
                    }
                }
			}

            // in case of just print the duplicated fields, exit
            if (opts.options.bPrintDuplicatedPattern) return(3);
		}

        //---------------------------------------------------------------------------------
		// now loop for each record in the file
        //---------------------------------------------------------------------------------
		foreach (rec; reader)
		{
            //---------------------------------------------------------------------------------
			// one more record read
            //---------------------------------------------------------------------------------
			stat.nbReadRecords++;

            //---------------------------------------------------------------------------------
			// if samples is set, break if line count is reached
            //---------------------------------------------------------------------------------
			if (opts.options.samples != 0 && stat.nbReadLines > opts.options.samples) 
            {
                break;
            }

            //---------------------------------------------------------------------------------
            // don't want a progress bar?
            //---------------------------------------------------------------------------------
            if (opts.options.bProgressBar && stat.nbReadRecords % chunkSize == 0)
            {
                if (reader.nbGuessedRecords != 0)
                    stat.progressBarStats(reader.nbGuessedRecords);
                    //stderr.writef(MSG066, nbReadRecords, reader.nbRecords, 
                    //        to!float(nbReadRecords)/reader.nbRecords*100, nbMatchedRecords);
                else
                    stderr.writef(MSG065, stat.nbReadRecords);
            }

            //---------------------------------------------------------------------------------
			// do we filter out records?
            //---------------------------------------------------------------------------------
			if (opts.isRecordFilterFileSet || opts.isRecordFilterSet)
			{
				if (!rec.matchRecordFilter(opts.filteredRecords)) continue;
                stat.nbMatchedRecords++;
			}

            //---------------------------------------------------------------------------------
			// don't want to write? Just loop
            //---------------------------------------------------------------------------------
			if (opts.options.bJustRead) continue;

            //---------------------------------------------------------------------------------
			// use our writer to generate the file
            //---------------------------------------------------------------------------------
			writer.write(rec);
			stat.nbWrittenRecords++;

            //---------------------------------------------------------------------------------
			// write sub records if any
            //---------------------------------------------------------------------------------
			if (opts.options.bBreakRecord)
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
        //writer.build("toto.txt");
		writer.close();

        //---------------------------------------------------------------------------------
		// print out some stats
        //---------------------------------------------------------------------------------
		auto elapsedtime = Clock.currTime() - starttime;

        stderr.writeln();
		//stderr.writefln(MSG014, reader.nbLinesRead, nbReadRecords, nbWrittenRecords);
        stat.finalStats();
		log.info(MSG015, elapsedtime);

		if (!opts.options.bJustRead)
        {
				stderr.writefln(MSG013, opts.outputFileName, getSize(opts.outputFileName));
        }

        //---------------------------------------------------------------------------------
        // if we wasked for checking formats, print out number of bad checks
        //---------------------------------------------------------------------------------
        if (opts.options.bCheckPattern)
        {
            stderr.writefln(MSG053, reader.nbBadCheck);
        }

        //---------------------------------------------------------------------------------
		// Detailed statistics on file?
        //---------------------------------------------------------------------------------
        if (opts.options.bDetailedStats)
        {
            stat.detailedStats();
        }

        //---------------------------------------------------------------------------------
		// and some logs
        //---------------------------------------------------------------------------------
        int seconds;
        elapsedtime.split!"seconds"(seconds);

        if (seconds != 0) log.info(MSG017, to!float(stat.nbReadRecords/seconds));
	}
	catch (Exception e) 
    {
		stderr.writeln(e.msg);
		return 1;
	}

    //---------------------------------------------------------------------------------
	// return successful code to OS
    //---------------------------------------------------------------------------------
	return 0;

}

