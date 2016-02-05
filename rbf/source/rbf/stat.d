module rbf.stat;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.conv;
import std.algorithm: sort;

import rbf.errormsg;


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

    void finalStats(File fh=stderr)
    {
		fh.writefln(MSG014, nbReadLines, nbReadRecords, nbWrittenRecords);
    }

    void progressBarStats(Counter nbGuessedRecords, File fh=stderr)
    {
        fh.writef(MSG066, nbReadRecords, nbGuessedRecords, to!float(nbReadRecords)/nbGuessedRecords*100, nbMatchedRecords);
    }

    void detailedStats(File fh=stderr)
    {
        fh.writeln;

        fh.writeln("Detailed stats:");
        fh.writeln("---------------------------------------");
        fh.writefln("number of lines read:      %d", nbReadLines);
        fh.writefln("number of records read:    %d", nbReadRecords);
        fh.writefln("number of records written: %d", nbWrittenRecords);
        fh.writefln("number of matched records: %d", nbMatchedRecords);

        fh.writeln;

        fh.writeln("List of records:");
        fh.writeln("---------------------------------------");
        foreach (recname; sort(nbRecs.keys))
        {
            if (nbRecs[recname] != 0) fh.writefln("%s : %d", recname, nbRecs[recname]);
        }
    }


}

// statistics global variable
Statistics stat;
