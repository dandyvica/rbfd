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


/***********************************
 * This class is holding command line arguments
 */
class CommandLineOption {

public:
	string inputFileName;						/// input file name to parse
	string inputLayout;							/// input file layout
	string outputFormat = "txt";		/// output format HTML, TXT, ...
	string outputFileName;					/// name of the final converted file

	string fieldFilterFile;					/// if any, name of the field filter file
	string fieldFilter;							/// if any, list of records/fields to filter out
	string recordFilterFile;				/// if any, name of the record filter file

	string lineFilter;							/// if any, define a regex to match lines

	bool bVerbose;									/// if true, print out lots of data
	bool bJustRead;									/// if true, don't write data
	bool bProgressBar;
	bool bCheckLayout;							/// if true, try to validate layouy by checking length
	bool stdOutput;									/// if true, print to standard output instead of file

	RecordFilter filteredRecords;
	string filteredFields;

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
			filteredFields = cast(string)std.file.read(fieldFilterFile);
		}
		if (fieldFilter != "") {
			filteredFields = fieldFilter;
		}

		// if filter file is specified, load conditions
		if (recordFilterFile != "") {
			filteredRecords = new RecordFilter(recordFilterFile);
		}

		// build output file name
		outputFileName = baseName(inputFileName) ~ "." ~ outputFormat;
	}

	@property bool isFieldFilterFileSet() { return fieldFilterFile != ""; }
	@property bool isFieldFilterSet()     { return fieldFilter != ""; }
	@property bool isRecordFilterSet()    { return recordFilterFile != ""; }

	/// useful helper
	void printOptions() {
		foreach (member; FieldNameTuple!CommandLineOption)
     {
				mixin("writeln(\"" ~ member ~ ": \"," ~ member ~ ");");
     }
	}

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
