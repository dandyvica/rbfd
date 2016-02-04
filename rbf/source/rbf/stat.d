module rbf.stat;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;

struct Statistics {
    uint nbReadLines;               // number of physical lines of the file
	uint nbReadRecords;
	uint nbWrittenRecords;
	uint nbMatchedRecords;
    uint shortestLine;
    uint longestLine;
}

// statistics global variable
Statistics stat;
