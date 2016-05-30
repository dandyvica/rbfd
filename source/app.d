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
import std.ascii;

import rbf.errormsg;
import rbf.log;
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.recordfilter;
import rbf.layout;
import rbf.reader;
import rbf.writers.writer;
import rbf.stat;
import rbf.config;
import rbf.settings;
import rbf.args;

// constants
immutable chunkSize = 1000;         /// print out message every chunkSize record
immutable CR = "\r";                /// carriage return

int main(string[] argv)
{
    // settings class for storing whole configuration
    Settings settings;

    //---------------------------------------------------------------------------------
	// need to known how much time spent
    //---------------------------------------------------------------------------------
	auto starttime = Clock.currTime();

	try 
    {
        // get global settings from config file and args
        settings.manage(argv);

        //---------------------------------------------------------------------------------
		// start logging data
        //---------------------------------------------------------------------------------
        log.info(MSG061, argv);
        log.info(MSG050, totalCPUs);

        //---------------------------------------------------------------------------------
		// define new layout corresponding to the requested layout given from the command line
        //---------------------------------------------------------------------------------
		auto layout = new Layout(settings.layoutConfiguration.file);

        //---------------------------------------------------------------------------------
		// need to get rid of some fields ?
        //---------------------------------------------------------------------------------
		if (settings.cmdLineOptions.isFieldFilterFileSet) 
        {
            //---------------------------------------------------------------------------------
			// only keep specified fields
            //---------------------------------------------------------------------------------
			layout.keepOnly(settings.cmdLineOptions.filteredFields, newline);
            log.info(MSG026, layout.size);
		}
        // list of records/fields given from the command line
		if (settings.cmdLineOptions.isFieldFilterSet) 
        {
            //---------------------------------------------------------------------------------
			// only keep specified fields
            //---------------------------------------------------------------------------------
			layout.keepOnly(settings.cmdLineOptions.filteredFields, ";");
            log.info(MSG026, layout.size);
		}

        //---------------------------------------------------------------------------------
		// create new reader according to what is passed in the command
		// line and the configuration found in XML properties file
        //---------------------------------------------------------------------------------
		auto reader = new Reader(settings.cmdLineOptions.cmdLineArgs.inputFileName, layout);
        log.info(MSG016, settings.cmdLineOptions.cmdLineArgs.inputFileName, reader.inputFileSize);

        //---------------------------------------------------------------------------------
		// check field patterns?
        //---------------------------------------------------------------------------------
        reader.checkPattern = settings.cmdLineOptions.cmdLineArgs.bCheckPattern;

        //---------------------------------------------------------------------------------
		// grep lines?
        //---------------------------------------------------------------------------------
		if (settings.cmdLineOptions.cmdLineArgs.lineFilter != "") 
        {
			reader.lineRegexPattern = settings.cmdLineOptions.cmdLineArgs.lineFilter;
		}

        //---------------------------------------------------------------------------------
		// if verbose option is requested, print out what's possible
        //---------------------------------------------------------------------------------
		if (settings.cmdLineOptions.cmdLineArgs.bVerbose) 
        {
            //---------------------------------------------------------------------------------
			// print out field type meta info
            //---------------------------------------------------------------------------------
			printMembers!(LayoutMeta)(layout.meta);
			foreach (t; layout.ftype) 
            {
				printMembers!(FieldTypeMeta)(t.meta);
			}
			printMembers!(CommandLineOption)(settings.cmdLineOptions);
			printMembers!(OutputConfiguration)(settings.outputConfiguration);
		}

        //---------------------------------------------------------------------------------
		// verify record filter arguments: if field name is not found in layout, stop
        //---------------------------------------------------------------------------------
        if (settings.cmdLineOptions.isRecordFilterFileSet || settings.cmdLineOptions.isRecordFilterSet)
        {
            foreach(rf; settings.cmdLineOptions.filteredRecords)
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
		writer = writerFactory(settings.output, settings.cmdLineOptions.cmdLineArgs.outputFormat);

        //---------------------------------------------------------------------------------
		// set writer features read in config and process preliminary steps
        //---------------------------------------------------------------------------------
        writer.settings = settings;

        // some writers need preliminary process
		writer.prepare(layout);

        //---------------------------------------------------------------------------------
		// break records?
        //---------------------------------------------------------------------------------
		if (settings.cmdLineOptions.cmdLineArgs.bBreakRecord || settings.cmdLineOptions.cmdLineArgs.bPrintDuplicatedPattern)
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
                    if (settings.cmdLineOptions.cmdLineArgs.bPrintDuplicatedPattern)
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
            if (settings.cmdLineOptions.cmdLineArgs.bPrintDuplicatedPattern) return(3);
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
			if (settings.cmdLineOptions.cmdLineArgs.samples != 0 && stat.nbReadLines > settings.cmdLineOptions.cmdLineArgs.samples) 
            {
                break;
            }

            //---------------------------------------------------------------------------------
            // don't want a progress bar?
            //---------------------------------------------------------------------------------
            if (settings.cmdLineOptions.cmdLineArgs.bProgressBar && stat.nbReadRecords % chunkSize == 0)
            {
                if (reader.nbGuessedRecords != 0)
                {
                    stat.progressBarStats(reader.nbGuessedRecords);
                }
                else
                {
                    writef(MSG065, stat.nbReadRecords);
                }
                // go back to beginning of the line
                write(CR);
                stdout.flush;
            }

            //---------------------------------------------------------------------------------
			// do we filter out records?
            //---------------------------------------------------------------------------------
			if (settings.cmdLineOptions.isRecordFilterFileSet || settings.cmdLineOptions.isRecordFilterSet)
			{
				if (!rec.matchRecordFilter(settings.cmdLineOptions.filteredRecords)) continue;
                stat.nbMatchedRecords++;
			}

            //---------------------------------------------------------------------------------
			// don't want to write? Just loop
            //---------------------------------------------------------------------------------
			if (settings.cmdLineOptions.cmdLineArgs.bJustRead) continue;

            //---------------------------------------------------------------------------------
			// use our writer to generate the file
            //---------------------------------------------------------------------------------

            // when using the template option, only write when record name is triggered
            if (settings.cmdLineOptions.cmdLineArgs.outputFormat != OutputFormat.temp || rec.name == settings.cmdLineOptions.cmdLineArgs.trigger) 
            {
    			writer.write(rec);
            }
			stat.nbWrittenRecords++;

            //---------------------------------------------------------------------------------
			// write sub records if any
            //---------------------------------------------------------------------------------
			if (settings.cmdLineOptions.cmdLineArgs.bBreakRecord)
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
		//stderr.writefln(MSG014, reader.nbLinesRead, nbReadRecords, nbWrittenRecords);
        stat.finalStats();
		log.info(MSG015, elapsedtime);

		if (!settings.cmdLineOptions.cmdLineArgs.bJustRead && 
             settings.cmdLineOptions.cmdLineArgs.outputFormat != OutputFormat.postgres)
        {
				stderr.writefln(MSG013, settings.cmdLineOptions.outputFileName, getSize(settings.cmdLineOptions.outputFileName));
        }

        //---------------------------------------------------------------------------------
        // if we wasked for checking formats, print out number of bad checks
        //---------------------------------------------------------------------------------
        if (settings.cmdLineOptions.cmdLineArgs.bCheckPattern)
        {
            stderr.writefln(MSG053, reader.nbBadCheck);
        }

        //---------------------------------------------------------------------------------
		// Detailed statistics on file?
        //---------------------------------------------------------------------------------
        if (settings.cmdLineOptions.cmdLineArgs.bDetailedStats)
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

