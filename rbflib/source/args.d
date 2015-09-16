module rbf.args;

import std.stdio;
import std.file;
import std.string;
import std.process;
import std.getopt;
import std.regex;
import std.algorithm;
import std.path;

import rbf.conf;
import rbf.filter;


/***********************************
 * This class is holding command line arguments
 */
class CommandLineOption {

public:
	string inputFileName;						/// input file name to parse
	string inputLayout;							/// input file layout
	string outputFormat = "txt";		/// output format HTML, TXT, ...
	string outputFileName;					/// name of the final converted file
	string fieldFilterFile;					/// if any, name of the clause file
	string recordFilterFile;
	string pgmVersion;
	bool   verbose = false;


	Filter filteredRecords;
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
		writeln("
NAME
	readrbf - read a record-based file and convert it to a known format

SYNOPSIS
	readrbf -i file - l layout [-o format] [-c file] [-r file] [-s n] [-v]

DESCRIPTION
	This program is aimed at reading a record-based file and converting it to
	a human-readable format. It reads its settings from the rbf.yaml configuration
	file located in the ~/.rbf directory (linux) or the %APPDATA%\\local\\rbf
	directory (Windows).

OPTIONS
	-i file
		Full path and name of the file to be read and converted.

	-l layout
		Name of the input file layout. This name is found is the
		configuration file rbf.yaml.

	-o format
		Name of the output file format. Possible values are:
		html, tag, csv, txt, xlsx, sqlite3. Defaulted to txt
		if not specified.

	-r file
		Full path and name of a file to filter records.

	-f file
		Full path and name of a file to filter fields.

	-s n
		Only convert the n-first records.

	-v
		Verbose: print out options

	-V
		Version.
		");
		core.stdc.stdlib.exit(1);
	}

	// get command line arguments
	getopt(argv,
		std.getopt.config.caseSensitive,
		std.getopt.config.required,
		"i", &inputFileName,
		std.getopt.config.required,
		"l", &inputLayout,
		"o", &outputFormat,
		"f", &fieldFilterFile,
		"r", &recordFilterFile,
		"V", &pgmVersion,
		"v", &verbose,
		"s", &samples
	);

	// check output format
	if (!["tag","txt","html","csv","xlsx","sqlite3"].canFind(outputFormat)) {
		throw new Exception("unknown input format %s".format(outputFormat));
	}

	// if no output file name specified, then use input file name and
	// append the suffix
	if (fieldFilterFile != "") {
		filteredFields = _readRestrictionFile(fieldFilterFile);
	}

	// if filter file is specified, load conditions
	if (recordFilterFile != "") {
		filteredRecords = new Filter(recordFilterFile);
	}

	// build output file name
	outputFileName = baseName(inputFileName) ~ "." ~ outputFormat;
}

/*
	@property string inputFileName() { return _inputFileName; }
	@property string outputFileName() { return _outputFileName; }
	@property string inputLayout() { return _inputLayout; }
	@property string outputFormat() { return _outputFormat; }
*/
	@property bool isFieldFilterSet() { return fieldFilterFile != ""; }
	@property bool isRecordFilterSet() { return recordFilterFile != ""; }

	void printOptions() {
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
	}

private:

/***********************************
	* function to read the list of fields for restricting fields
 */
 string[][string] _readRestrictionFile(in string filename) {
	  string[][string] fieldNames;

		foreach (string line_read; lines(File(filename, "r"))) {
			// each line is like: RECORD1:FIEDL1,FIELD2,FIELD6,...
			auto line = chomp(line_read);

			// first, ignore comments
			if (matchFirst(line, regex("^#"))) continue;

			// and blank lines
			if (line == "") continue;

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
