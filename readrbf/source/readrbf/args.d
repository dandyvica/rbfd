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
	string fieldFilterFile;					/// if any, name of the field fitler file
	string recordFilterFile;				/// if any, name of the record filter file

	bool bPgmMetadata;						  /// whether to print out metadat
	bool bVerbose;
	bool bJustRead;									/// if true, don't write data
	bool bProgressBar;
	bool bCheckLayout;
	bool stdOutput;									/// if true, print to standard output

	RecordFilter filteredRecords;
	string[][string] filteredFields;

	ulong samples;						/// limit to n first lines



public:
/***********************************
 * Process command line arguments
 */
 	this(string[] argv) {

	// print-out help
	if (argv.length == 1)
	{
		writeln(helpString);
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
			"r", &recordFilterFile,
			"m", &bPgmMetadata,
			"v", &bVerbose,
			"s", &samples,
			"b", &bJustRead,
			"p", &bProgressBar,
			"c", &bCheckLayout
		);
	}
	catch (Exception e) {
		writefln("Argument error: %s", e.msg);
		core.stdc.stdlib.exit(2);
	}

	// check output format
	enforce (["tag","txt","html","csv","xlsx","sqlite3","ident"].
				canFind(outputFormat), "error: unknown input format %s".format(outputFormat));

/*
	if (!["tag","txt","html","csv","xlsx","sqlite3","ident"].canFind(outputFormat)) {
		throw new Exception("error: unknown input format %s".format(outputFormat));
	}*/

	// if no output file name specified, then use input file name and
	// append the suffix
	if (fieldFilterFile != "") {
		filteredFields = _readFieldFilterFile(fieldFilterFile);
	}

	// if filter file is specified, load conditions
	if (recordFilterFile != "") {
		filteredRecords = new RecordFilter(recordFilterFile);
	}

	// build output file name
	outputFileName = baseName(inputFileName) ~ "." ~ outputFormat;
}

	@property bool isFieldFilterSet() { return fieldFilterFile != ""; }
	@property bool isRecordFilterSet() { return recordFilterFile != ""; }

	/// useful helper
	void printOptions() {
		foreach (member; FieldNameTuple!CommandLineOption)
     {
				mixin("writeln(\"" ~ member ~ ": \"," ~ member ~ ");");
     }

/*
		writefln("input file: %s", inputFileName);
		writefln("file layout: %s", inputLayout);
		writefln("output format: %s", outputFormat);
		writefln("output file name: %s", outputFileName);
		writefln("samples: %u", samples);
		if (isFieldFilterSet) {
			writefln("field filter file: %s", fieldFilterFile);
			writefln("\tfields to filter: %s", filteredFields);
		}
		if (isRecordFilterSet) {
			writefln("record filter file: %s", recordFilterFile);
			writefln("\trecords to filter: %s", filteredRecords);
		}
*/
	}

private:

/***********************************
	* function to read the list of fields for restricting fields
 */
 string[][string] _readFieldFilterFile(in string filename) {
	  string[][string] fieldNames;

		foreach (string line_read; lines(File(filename, "r"))) {
			// each line is like: RECORD1:FIEDL1,FIELD2,FIELD6,...
			auto line = chomp(line_read);

			// first, ignore comments and blank lines
			if (line == "" || line.startsWith("#")) continue;

			// ok, now split line and extract record name for the key
			// and field names for the values
			// e.g: RECORD1: FIELD1,FIELD2, FIELD3
			auto data = line.split(":");

			// record name is found before the : char
			auto recordName = data[0].strip;

			// and all fields on the right
			auto fieldList =  data[1].strip;

			// no list specified or '*' found: we want all fields of this record
			if (fieldList == "" || fieldList == "*") {
				fieldNames[recordName] = [];
				continue;
			}

			// otherwise build list of field names
			foreach (fieldName; fieldList.split(",")) {
				fieldNames[recordName] ~= fieldName.strip;
			}
		}

		// ok we've got our list indexed by record name
		return fieldNames;
 }
}


unittest {
	writefln("-------------------------------------------------------------");
	writeln(__FILE__);
	writefln("-------------------------------------------------------------");

/*
	auto c = new Config();

	writeln(c["hot220"]);

	auto x = "BKS1111111124 4444";
	writeln(c["hot220"].record_identifier(x));*/

}
