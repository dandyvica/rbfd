module rbf.stat;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.format;
import std.conv;
import std.algorithm: sort;

import rbf.errormsg;
import rbf.log;


// alias for all counters (nb lines, records, ...)
alias Counter = ulong;

struct Statistics 
{
    Counter nbReadLines;               // number of physical lines of the file
	Counter nbReadRecords;             // number of lines transformed into records (might be different from previous)
	Counter nbWrittenRecords;          // number of records effectively written to disk
	Counter nbMatchedRecords;          // number of matched conditions when using the record filter 
    Counter shortestLine;              // sometimes, not all lines are even.
    Counter longestLine;               // calculate shortest and longest to get an idea of how the file diverts from spec

    Counter[string] nbRecs;            // keep number of records in the file per record

    void finalStats(ref Log log)
    {
		log.info(Message.MSG014, nbReadLines, nbReadRecords, nbWrittenRecords);
    }

    void progressBarStats(Counter nbGuessedRecords, ref Log log)
    {
        stderr.writef(Message.MSG066.format(nbReadRecords, nbGuessedRecords, to!float(nbReadRecords)/nbGuessedRecords*100, nbMatchedRecords));
    }

    void detailedStats(ref Log log)
    {
        foreach (recname; sort(nbRecs.keys))
        {
            if (nbRecs[recname] != 0) 
            {
                log.info(Message.MSG096, recname, nbRecs[recname]);
            }
        }
    }


}

// statistics global variable
Statistics stat;
