module rbf.util;

import std.stdio;
import std.file;
import std.string;
import std.process;
import std.json;
import std.conv;
import std.path;

/***********************************
 * This structure is holding command line arguments
 */
struct CommandLineOption
{
	string inputFileName;		// input file name to parse
	string outputFileName;		// output file name to save
	string outputMode;			// output mode HTML, TXT, ...
	string inputFormat;			// input file format
	string conditionFile;		// if any, name of the clause file
}

enum mapperType { STRING_MAPPER, VARIABLE_MAPPER }

/***********************************
 * This class is holding configuration specific to a rbf format
 */
struct RBFConfig
{
	string xmlStructure;		/// XML description of the format
	string[] sliceList;					/// list of slices to build record identifier
	string ignorePattern;		/// if any, ignore those lines when reading

	string record_identifier(string x) {
		// result is either a constant string or depending on string passed
		string[] result;

		foreach (slice; sliceList) {
			// slice is like '0:2', so we need to extract 0 and 2
			auto bounds = slice.split(':');
			auto lower_bound = to!int(bounds[0]);
			auto upper_bound = to!int(bounds[1]);

			// and get slice from string
			result ~= x[lower_bound..upper_bound];
		}

		return join(result, "");
	}

/*
	this(in string xmlStructure, in string ignorePattern) {
		this.xmlStructure = xmlStructure;
		this.ignorePattern = ignorePattern;
	}*/
}

/***********************************
	* class for reading JSON property file
 */
class Config {
private:
	JSONValue[string] tags;						/// tags as read from the JSON settings file

public:
	/**
	 * read the JSON configuration file (or settings file)
	 *
	 * Examples:
	 * --------------
	 * auto conf = new Config();
	 * --------------
	 */
	this() {

		// settings file location is OS-dependent
		version(linux) {
			immutable string settingsFile = expandTilde("~/.rbf/rbf.json");
		}
		version(win64) {
				immutable string settingsFile = environment["APPDATA"] +
					"/local/rbf/rbf.json";
		}
		// ensure file exists
		std.exception.enforce(exists(settingsFile), "Settings file %s not found".format(settingsFile));

		// Ok, now read JSON
		auto jsonTags = to!string(read(settingsFile));
		tags = parseJSON(jsonTags).object;
	}

	RBFConfig opIndex(string rbfFormat) {
		string ignorePattern;

		// xml file structure
		auto xmlStructure = tags["xml"][rbfFormat]["xmlfile"].str;

		// list of ranges used to build lambda
		auto mapping = tags["xml"][rbfFormat]["mapping"].str;

		// if ':' is found, this is a list of ranges
		string[] slices;
		if (mapping.indexOf(':') != -1) {
			// split and build our ranges
			slices = mapping.split(",");
		}
		else
			slices ~= mapping;

		// ignore pattern might not be found
		if ("ignore" in tags["xml"][rbfFormat]) {
			ignorePattern = tags["xml"][rbfFormat]["ignore"].str;
		}

		// return structure
		return RBFConfig(xmlStructure, slices, ignorePattern);
	}
}

unittest {
	writefln("-------------------------------------------------------------");
	writeln(__FILE__);
	writefln("-------------------------------------------------------------");

	auto c = new Config();

	writeln(c["hot220"]);

	auto x = "BKS1111111124 4444";
	writeln(c["hot220"].record_identifier(x));

}
