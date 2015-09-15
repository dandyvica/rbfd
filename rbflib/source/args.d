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

private:
	string _inputFileName;		// input file name to parse
	string _outputFileName;	// output file name to save
	string _outputDirectoryName; // directory for saving file
	string _inputFormat;			// input file format
	string _outputFormat = "txt";		// output format HTML, TXT, ...
	string _filterFile;		// if any, name of the clause file
	Filter _filter;

	string _restrictionFile;	// name of the file containing subset list of fields
	string[][string] _fieldNames;



public:
/***********************************
 * Process command line arguments
 */
 	this(string[] argv) {

	// print-out help
	if (argv.length == 1)
	{
		writeln("
This program is aimed at reading record-based files.
It reads its settings from the rbf.json file located in the ~/.rbf directory
(linux) or the %APPDATA%\\local\\rbf directory (Windows).

Usage: readrbf -i <input file name> -O <output file> -o <output format> -f <input format> -c <cond file>

	-i		mandatory: input file name to read
	-f		mandatory: input file format (ex:: isr)
	-o		optional: output directory name. If not specified, current directory
	-F		optional: output file format, should be only: html, tag, csv, txt, xlsx or sqlite3.
				If not specified, default to \"txt\"
	-c		optional: a set of conditions for filtering records
	-r		optional: a file containing a list of records/fields to get
		");
		core.stdc.stdlib.exit(1);
	}

	// get command line arguments
	CommandLineOption opts;
	getopt(argv,
		std.getopt.config.caseSensitive,
		std.getopt.config.required,
		"i", &_inputFileName,
		std.getopt.config.required,
		"f", &_inputFormat,
		"o", &_outputDirectoryName,
		"F", &_outputFormat,
		"c", &_filterFile,
		"r", &_restrictionFile
	);

	// check input format
	if (!["tag","txt","html","csv","xlsx","sqlite3"].canFind(_outputFormat)) {
		throw new Exception("unknown input format %s".format(_outputFormat));
	}

	// if no output file name specified, then use input file name and
	// append the suffix
	if (_restrictionFile != "") {
		_fieldNames = _readRestrictionFile(_restrictionFile);
	}

  // if no output directory is specified, then use current directory
	if (_outputDirectoryName == "") {
		_outputDirectoryName = "./";
	}

	// if filter file is specified, load conditions
	if (_filterFile != "") {
		_filter = new Filter(_filterFile);
	}

	// build output file name
	_outputFileName = _outputDirectoryName ~ "/" ~
			baseName(_inputFileName) ~ "." ~_outputFormat;
}

	@property string inputFileName() { return _inputFileName; }
	@property string outputFileName() { return _outputFileName; }
	@property string inputFormat() { return _inputFormat; }
	@property string outputFormat() { return _outputFormat; }
	@property bool isRestriction() { return _restrictionFile != ""; }
	@property bool isFilter() { return _filterFile != ""; }
	@property string[][string] fieldNames() { return _fieldNames; }
	@property Filter filter() { return _filter; }

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
