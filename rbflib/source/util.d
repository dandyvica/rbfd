import std.stdio;
import std.file;
import std.string;
import std.process;
import std.json;
import std.conv;

// structure for holding arguments
struct CommandLineOption
{
	string inputFileName;		// input file name to parse
	string outputFileName;		// output file name to save
	string outputMode;			// output mode HTML, TXT, ...
	string inputFormat;			// input file format
	string conditionFile;		// if any, name of the clause file
}

// class for reading JSON property file
class Config {
public:
	immutable string xmlStructure;		/// XML description of the format
	immutable string ignorePattern;		/// if any, ignore those lines when reading

	immutable string envJSON = "RBFCONF";  /// name of the enviroment variable
																				 /// holding the JSON file name
  // just one ctor
	this(in string inputFormat) {
		// read env variable
		auto jsonFile = environment[envJSON];

		// no env or file not found?
		if (jsonFile == "") {
			throw new Exception("environment variable %s not found!".format(envJSON));
		}
		std.exception.enforce(exists(jsonFile), "JSON definition file %s not found".format(jsonFile));

		// Ok, now read JSON
		auto jsonTags = to!string(read(jsonFile));
		JSONValue[string] tags = parseJSON(jsonTags).object;

		//writeln(tags["xml"][inputFormat]);

  	// configuration is mainly found in the xml JSON tag
		xmlStructure = tags["xml"][inputFormat]["xmlfile"].str;

		// ignore pattern might not be found
		if ("ignore" in tags["xml"][inputFormat]) {
			ignorePattern = tags["xml"][inputFormat]["ignore"].str;
		}



	}
}

unittest {
	writefln("-------------------------------------------------------------");
	writeln(__FILE__);
	writefln("-------------------------------------------------------------");

	auto c = new Config("hot203");


}
