module rbf.config;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.process;
import std.json;
import std.conv;
import std.path;
import std.typecons;
import std.algorithm;
import std.range;
import std.functional;
import std.regex;

import yaml;

alias RECORD_MAPPER = string delegate(string);

/// configuration file name
immutable yamlSettings = "rbf.yaml";


/***********************************
	* struct for describing layout metadata
 */
struct LayoutConfig {
  string description;         /// a short description of the layout
  string mapping;             /// how to map a read line to a record object?
  string xmlFile;             /// XML definition of layout
  Regex!char ignoreRecord;    /// in some case, we need to get rid of some lines
  string skipField;           /// in some cases, don't take into account some fields
  string layoutType;          /// what kind of layout is it?

  // mapper is used to find a record name from a line read from file
  RECORD_MAPPER mapper;
}

/***********************************
	* class for reading JSON property file
 */
class Setting {
private:
  Node _document;       /// object holding all settings
  string _zipper;       /// path/name of the excutable used tip zip .xlsx
  string _rbfhome;      /// path of the user directory

public:
	/**
	 * read the YAML configuration file
	 *
   * Params:
	 * 	yamlConfigFile = optional file configuration file
	 */
	this(string yamlConfigFile) {

    // settings file
    string settingsFile;

    // if file is passed, take it
    if (yamlConfigFile != "") {
      settingsFile = yamlConfigFile;
    }
    else {
      // first possible location is current directory
      if (exists(getcwd ~ yamlSettings)) {
        settingsFile = getcwd ~ yamlSettings;
      }
      else {
        // YAML settings file location is OS-dependent
        version(linux) {
          _rbfhome = environment["HOME"] ~ "/.rbf/";
          settingsFile = _rbfhome ~ "rbf.yaml";
        }
        version(win64) {
          _rbfhome = environment["APPDATA"];
           settingsFile = _rbfhome ~ `\local\rbf\rbf.yaml`;
        }
      }
    }

		// ensure file exists
		std.exception.enforce(exists(settingsFile), "Settings file %s not found".format(settingsFile));

    // Read YAML file
    _document = Loader(settingsFile).load();

    // save location of zipper executable
		version(linux) {
			_zipper = _document["global"]["zipper"]["linux"].as!string;
		}
		version(win64) {
      _zipper = _document["global"]["zipper"]["win64"].as!string;
		}

  }

  @property string zipper() { return _zipper; }

  LayoutConfig opIndex(string layoutName) {
    LayoutConfig conf = LayoutConfig();

    // copy all data from layout YAML config file for specified layout
    // those are mandatory
    conf.description = _document["layout"][layoutName]["description"].as!string;
    conf.mapping     = _document["layout"][layoutName]["mapping"].as!string;
    conf.xmlFile     = _rbfhome ~ _document["layout"][layoutName]["xmlFile"].as!string;

    // those are optional
    if ("ignoreRecord" in _document["layout"][layoutName])
      conf.ignoreRecord = regex(_document["layout"][layoutName]["ignoreRecord"].as!string);

    if ("skipField" in _document["layout"][layoutName])
      conf.skipField     = _document["layout"][layoutName]["skipField"].as!string;

    if ("layoutType" in _document["layout"][layoutName])
      conf.layoutType    = _document["layout"][layoutName]["layoutType"].as!string;

    // build mapper
    // if constant mapper, it's easy
    if (!conf.mapping.canFind("..")) {
      conf.mapper = delegate(string s) { return conf.mapping; };
    }
    // dynamically build our mapper depending on slices
    else {
      int[][] slices;
      foreach (slice; conf.mapping.split(",")) {
        slices ~= array(slice.split("..").map!(x => to!int(x)));
      }
      conf.mapper = delegate(string s) {
        return array(slices.map!(x => s[x[0]..x[1]])).join("");
      };
    }


    return conf;
  }

}



unittest {
	writefln("-------------------------------------------------------------");
	writeln(__FILE__);
	writefln("-------------------------------------------------------------");

  auto s = "aaaaaaaaaaaaaaaaaaaaaaa";




	auto c = new Setting();

	writeln(c.zipper);
  writeln(c["emdlift"]);
  writeln(c["missales27"]);
  writeln(c["hot220"]);
  writeln(c["hot220"].mapper("BKS1234567824"));
}
