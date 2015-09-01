module rbf.util;

import std.stdio;
import std.file;
import std.string;
import std.process;
import std.json;
import std.conv;
import std.path;
import std.typecons;

/***********************************
 * This structure is holding command line arguments
 */
struct CommandLineOption
{
	string inputFileName;		// input file name to parse
	string outputFileName;	// output file name to save
	string inputFormat;			// input file format
	string outputFormat;		// output format HTML, TXT, ...
	string conditionFile;		// if any, name of the clause file
}

enum mapperType { STRING_MAPPER, VARIABLE_MAPPER }

/***********************************
 * This class is holding configuration specific to a rbf format
 */
class RBFConfig
{
private:
  string _structureName;	/// name of the rb format
	string _xmlStructure;		/// XML description of the format

	alias Slice = Tuple!(int, int);

	mapperType _mappingType;	/// is it a constant or variable mapper?
	string _constantMapping;	/// case of a constant mapper
	Slice[] _sliceMapping;	  /// list of slices to build record identifier (variable mapper)

	string _ignorePattern;	/// if any, ignore those lines when reading


public:
	this(in string name, JSONValue tag) {
		// save the name of this structure
		_structureName = name;

		// save XML file name
		_xmlStructure = tag["xmlfile"].str;

		// ignore pattern might not be found
		if ("ignore" in tag) {
			_ignorePattern = tag["ignore"].str;
		}

		// get mapping
		if ("constant" in tag["mapping"]) {
			_mappingType = mapperType.STRING_MAPPER;
			_constantMapping = tag["mapping"]["constant"].str;
		}
		else if ("variable" in tag["mapping"]) {
			_mappingType = mapperType.VARIABLE_MAPPER;

			// slices oare just an array of tuples
			foreach (slice; tag["mapping"]["variable"].str.split(",")) {
				// slice is like '0:2', so we need to extract 0 and 2
				auto bounds = slice.split(':');
				auto lower_bound = to!int(bounds[0]);
				auto upper_bound = to!int(bounds[1]);

				// and get slice from string
				_sliceMapping ~= Slice(lower_bound, upper_bound);
			}

			// build our list of slices
		}
		else
				throw new Exception("no constant or variable mapper defined for format %s".format(_structureName));
	}

	@property string xmlStructure() { return _xmlStructure; }
	@property string ignorePattern() { return _ignorePattern; }

	string record_identifier(string x) {
		string result;

		// depending on type, return a constant or a list of values
		if (_mappingType == mapperType.STRING_MAPPER)
			result = _constantMapping;
		else if (_mappingType == mapperType.VARIABLE_MAPPER) {
			foreach (slice; _sliceMapping) {
				result ~= x[slice[0]..slice[1]];
			}
		}

		// result value
		return result;
	}

	override string toString() {
		return "<%s>: structure file=<%s>, ignore pattern=<%s>, mapping=<%s>"
			.format(_structureName, _xmlStructure, _ignorePattern, _sliceMapping);
	}
}

/***********************************
	* class for reading JSON property file
 */
class Config {
private:
	JSONValue[string] document;						/// tags as read from the JSON settings file
	RBFConfig[string] conf;						/// individual config for one XML structure

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
		document = parseJSON(jsonTags).object;

		// now fetch "xml" tag
		JSONValue[string] xmlTag = document["xml"].object;

		// and create array of XML configs
		foreach (tag; xmlTag.keys) {
			conf[tag] = new RBFConfig(tag, xmlTag[tag]);
		}
	}

	RBFConfig opIndex(string rbfFormat) {
		return conf[rbfFormat];
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
