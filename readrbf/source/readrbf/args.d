module args;

import std.stdio;
import std.file;
import std.string;
import std.process;
import std.getopt;
import std.regex;
import std.algorithm;
import std.path;
import std.exception;
import std.traits;

import rbf.recordfilter;

immutable helpString = import("help.txt");

// common members



/***********************************
 * This class is holding command line arguments
 */
struct CommandLineOption {

public:
	string inputFileName;						/// input file name to parse
	string inputLayout;							/// input file layout
	string outputFormat = "txt";		/// output format HTML, TXT, ...
	string outputFileName;					/// name of the final converted file

	string fieldFilterFile;					/// if any, name of the field filter file
	string fieldFilter;							/// if any, list of records/fields to filter out
	string recordFilterFile;				/// if any, name of the record filter file
	string recordFilter;						/// if any, name of the record filter file
	RecordFilter filteredRecords;   /// if any, list of clauses to filter records
	string filteredFields;					/// if nay list of fields to filter out


	string lineFilter;							/// if any, define a regex to match lines

	bool bVerbose;									/// if true, print out lots of data
	bool bJustRead;									/// if true, don't write data
	bool bProgressBar;
	bool bCheckLayout;							/// if true, try to validate layouy by checking length
	bool stdOutput;									/// if true, print to standard output instead of file


	ulong samples;									/// limit to n first lines (n == samples)



public:
/***********************************
 * Process command line arguments
 */
 	this(string[] argv) {

		// print-out help
		if (argv.length == 1)
		{
			writeln(helpString);
			writefln("\nCompiled on %s with %s version %d\n", __DATE__, __VENDOR__, __VERSION__);
			core.stdc.stdlib.exit(1);
		}

		try {
			// get command line arguments
			getopt(argv,
				std.getopt.config.caseSensitive,
				std.getopt.config.required,
				"i", &inputFileName,
				std.getopt.config.required,
				"l", &inputLayout,
				"o", &outputFormat,
				"O", &stdOutput,
				"f", &fieldFilterFile,
				"gf", &fieldFilter,
				"gl", &lineFilter,
				"r", &recordFilterFile,
				"gr", &recordFilter,
				"v", &bVerbose,
				"s", &samples,
				"b", &bJustRead,
				"p", &bProgressBar,
				"c", &bCheckLayout
			);
		}
		catch (Exception e) {
			stderr.writefln("error: %s", e.msg);
			core.stdc.stdlib.exit(2);
		}

		// if no output file name specified, then use input file name and
		// append the suffix
		if (fieldFilterFile != "") {
			enforce(exists(fieldFilterFile), "error: field filter file %s not found".format(fieldFilterFile));
			filteredFields = cast(string)std.file.read(fieldFilterFile);
		} else if (fieldFilter != "") {
			filteredFields = fieldFilter;
		}

		// if filter file is specified, load conditions
		if (recordFilterFile != "") {
			enforce(exists(recordFilterFile), "error: field filter file %s not found".format(recordFilterFile));
			filteredRecords = new RecordFilter(cast(string)std.file.read(recordFilterFile), "\n");
		} else if (recordFilter != "") {
			filteredRecords = new RecordFilter(recordFilter, ";");
		}

		// build output file name
		outputFileName = baseName(inputFileName) ~ "." ~ outputFormat;
	}

	@property bool isFieldFilterFileSet()  { return fieldFilterFile != ""; }
	@property bool isFieldFilterSet()      { return fieldFilter != ""; }
	@property bool isRecordFilterFileSet() { return recordFilterFile != ""; }
	@property bool isRecordFilterSet()     { return recordFilter != ""; }

}
///
unittest {
	writeln("========> testing ", __FILE__);

	auto argv = ["", "-i", "foo.input"];
	assertThrown(new CommandLineOption(argv));

	argv = ["", "-l", "xml"];
	assertThrown(new CommandLineOption(argv));

	argv = ["", "-i", "foo.input", "-l", "xml"];
	auto c = new CommandLineOption(argv);
	assert(c.inputFileName == "foo.input");
	assert(c.inputLayout == "xml");

	core.stdc.stdlib.exit(2);
}
