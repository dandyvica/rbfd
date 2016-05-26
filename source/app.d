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
import rbf.config;
import rbf.stat;

import args;

// constants
immutable chunkSize = 1000;         /// print out message every chunkSize record
immutable CR = "\r";                /// carriage return

int main(string[] argv)
{
    // settings class for storing whole configuration
    Config configFromXMLFile;

    //---------------------------------------------------------------------------------
	// need to known how much time spent
    //---------------------------------------------------------------------------------
	auto starttime = Clock.currTime();

	try 
    {

        //---------------------------------------------------------------------------------
		// manage arguments passed from the command line
        //---------------------------------------------------------------------------------
		auto cmdLineOptions = CommandLineOption(argv);

        //---------------------------------------------------------------------------------
		// configuration file passed as arugment? Use it if neccessary
        //---------------------------------------------------------------------------------
        if (cmdLineOptions.cmdLineArgs.cmdlineConfigFile != "")
        {
            configFromXMLFile = new Config(cmdLineOptions.cmdLineArgs.cmdlineConfigFile);
        }
        else
        {
            // take the default configuration file
		    configFromXMLFile = new Config();
        }

        //---------------------------------------------------------------------------------
		// start logging data
        //---------------------------------------------------------------------------------
        log.info(MSG061, argv);
        log.info(MSG050, totalCPUs);

        //---------------------------------------------------------------------------------
		// define new layout corresponding to the requested layout given from the command line
        //---------------------------------------------------------------------------------
		auto layout = new Layout(configFromXMLFile.layoutList[cmdLineOptions.cmdLineArgs.inputLayout].file);

        //---------------------------------------------------------------------------------
		// output format is an enum but should match the string in rbf.xml config file
        //---------------------------------------------------------------------------------
        auto outputFormat = to!string(cmdLineOptions.cmdLineArgs.outputFormat);

        //---------------------------------------------------------------------------------
		// use output file name if given or build it
        //---------------------------------------------------------------------------------
        if (cmdLineOptions.cmdLineArgs.givenOutputFileName != "")
        {
            cmdLineOptions.outputFileName = cmdLineOptions.cmdLineArgs.givenOutputFileName;
        }
        else
        {
            cmdLineOptions.outputFileName = baseName(cmdLineOptions.cmdLineArgs.inputFileName) ~ "." ~ configFromXMLFile.outputList[outputFormat].outputFileExtension;
        }

        //---------------------------------------------------------------------------------
		// check if œoutput format is valid
        //---------------------------------------------------------------------------------
		if (outputFormat !in configFromXMLFile.outputList) 
        {
			throw new Exception(MSG058.format(configFromXMLFile.outputList.names));
		}

        //---------------------------------------------------------------------------------
		// layout syntax validation requested from command line ?
        //---------------------------------------------------------------------------------
        /*
		if (cmdLineOptions.cmdLineArgs.bCheckLayout) 
        {
			layout.validate;
		}
        */

        //---------------------------------------------------------------------------------
		// use alternate names if requested
        //---------------------------------------------------------------------------------
		if (cmdLineOptions.cmdLineArgs.bUseAlternateNames) 
        {
			configFromXMLFile.outputList[outputFormat].useAlternateName = true;
		}

        //---------------------------------------------------------------------------------
		// save template file if any
        //---------------------------------------------------------------------------------
		if (cmdLineOptions.cmdLineArgs.templateFile != "") 
        {
			configFromXMLFile.outputList[outputFormat].templateFile = cmdLineOptions.cmdLineArgs.templateFile;
		}

        //---------------------------------------------------------------------------------
		// need to get rid of some fields ?
        //---------------------------------------------------------------------------------
		if (cmdLineOptions.isFieldFilterFileSet) 
        {
            //---------------------------------------------------------------------------------
			// only keep specified fields
            //---------------------------------------------------------------------------------
			layout.keepOnly(cmdLineOptions.filteredFields, newline);
            log.info(MSG026, layout.size);
		}
        // list of records/fields given from the command line
		if (cmdLineOptions.isFieldFilterSet) 
        {
            //---------------------------------------------------------------------------------
			// only keep specified fields
            //---------------------------------------------------------------------------------
			layout.keepOnly(cmdLineOptions.filteredFields, ";");
            log.info(MSG026, layout.size);
		}

        //---------------------------------------------------------------------------------
		// create new reader according to what is passed in the command
		// line and the configuration found in XML properties file
        //---------------------------------------------------------------------------------
		auto reader = new Reader(cmdLineOptions.cmdLineArgs.inputFileName, layout);
        log.info(MSG016, cmdLineOptions.cmdLineArgs.inputFileName, reader.inputFileSize);

        //---------------------------------------------------------------------------------
		// check field patterns?
        //---------------------------------------------------------------------------------
        reader.checkPattern = cmdLineOptions.cmdLineArgs.bCheckPattern;

        //---------------------------------------------------------------------------------
		// grep lines?
        //---------------------------------------------------------------------------------
		if (cmdLineOptions.cmdLineArgs.lineFilter != "") 
        {
			reader.lineRegexPattern = cmdLineOptions.cmdLineArgs.lineFilter;
		}

        //---------------------------------------------------------------------------------
		// if verbose option is requested, print out what's possible
        //---------------------------------------------------------------------------------
		if (cmdLineOptions.cmdLineArgs.bVerbose) 
        {
            //---------------------------------------------------------------------------------
			// print out field type meta info
            //---------------------------------------------------------------------------------
			printMembers!(LayoutMeta)(layout.meta);
			foreach (t; layout.ftype) 
            {
				printMembers!(FieldTypeMeta)(t.meta);
			}
			printMembers!(CommandLineOption)(cmdLineOptions);
			printMembers!(OutputFeature)(configFromXMLFile.outputList[outputFormat]);
		}

        //---------------------------------------------------------------------------------
		// verify record filter arguments: if field name is not found in layout, stop
        //---------------------------------------------------------------------------------
        if (cmdLineOptions.isRecordFilterFileSet || cmdLineOptions.isRecordFilterSet)
        {
            foreach(rf; cmdLineOptions.filteredRecords)
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
				configFromXMLFile.outputList[outputFormat].outputDirectory,
				cmdLineOptions.outputFileName
		);

		auto output = (cmdLineOptions.cmdLineArgs.stdOutput) ? "" : outputFileName;
		writer = writerFactory(output, cmdLineOptions.cmdLineArgs.outputFormat);

        //---------------------------------------------------------------------------------
		// set writer features read in config and process preliminary steps
        //---------------------------------------------------------------------------------
		writer.outputFeature = configFromXMLFile.outputList[outputFormat];
		writer.configFromXMLFile = configFromXMLFile;
        writer.inputFileName = cmdLineOptions.cmdLineArgs.inputFileName;

        // SQL format adds additonal feature for SQL
        if  (cmdLineOptions.cmdLineArgs.outputFormat == OutputFormat.sql || cmdLineOptions.cmdLineArgs.outputFormat == OutputFormat.postgres) 
        {
            writer.outputFeature.sqlPreFile  = cmdLineOptions.cmdLineArgs.sqlPreFile;
            writer.outputFeature.sqlPostFile = cmdLineOptions.cmdLineArgs.sqlPostFile;
        }

        // add additional parameters
        writer.outputFeature.useRawValue = cmdLineOptions.cmdLineArgs.useRawValue;

        // some writers need preliminary process
		writer.prepare(layout);

        //---------------------------------------------------------------------------------
		// break records?
        //---------------------------------------------------------------------------------
		if (cmdLineOptions.cmdLineArgs.bBreakRecord || cmdLineOptions.cmdLineArgs.bPrintDuplicatedPattern)
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
                    if (cmdLineOptions.cmdLineArgs.bPrintDuplicatedPattern)
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
            if (cmdLineOptions.cmdLineArgs.bPrintDuplicatedPattern) return(3);
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
			if (cmdLineOptions.cmdLineArgs.samples != 0 && stat.nbReadLines > cmdLineOptions.cmdLineArgs.samples) 
            {
                break;
            }

            //---------------------------------------------------------------------------------
            // don't want a progress bar?
            //---------------------------------------------------------------------------------
            if (cmdLineOptions.cmdLineArgs.bProgressBar && stat.nbReadRecords % chunkSize == 0)
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
			if (cmdLineOptions.isRecordFilterFileSet || cmdLineOptions.isRecordFilterSet)
			{
				if (!rec.matchRecordFilter(cmdLineOptions.filteredRecords)) continue;
                stat.nbMatchedRecords++;
			}

            //---------------------------------------------------------------------------------
			// don't want to write? Just loop
            //---------------------------------------------------------------------------------
			if (cmdLineOptions.cmdLineArgs.bJustRead) continue;

            //---------------------------------------------------------------------------------
			// use our writer to generate the file
            //---------------------------------------------------------------------------------

            // when using the template option, only write when record name is triggered
            if (cmdLineOptions.cmdLineArgs.outputFormat != OutputFormat.temp || rec.name == cmdLineOptions.cmdLineArgs.trigger) 
            {
    			writer.write(rec);
            }
			stat.nbWrittenRecords++;

            //---------------------------------------------------------------------------------
			// write sub records if any
            //---------------------------------------------------------------------------------
			if (cmdLineOptions.cmdLineArgs.bBreakRecord)
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

		if (!cmdLineOptions.cmdLineArgs.bJustRead)
        {
				stderr.writefln(MSG013, cmdLineOptions.outputFileName, getSize(cmdLineOptions.outputFileName));
        }

        //---------------------------------------------------------------------------------
        // if we wasked for checking formats, print out number of bad checks
        //---------------------------------------------------------------------------------
        if (cmdLineOptions.cmdLineArgs.bCheckPattern)
        {
            stderr.writefln(MSG053, reader.nbBadCheck);
        }

        //---------------------------------------------------------------------------------
		// Detailed statistics on file?
        //---------------------------------------------------------------------------------
        if (cmdLineOptions.cmdLineArgs.bDetailedStats)
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

