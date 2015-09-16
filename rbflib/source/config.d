module rbf.config;

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

//static Config configSettings;

import yaml;

alias RECORD_MAPPER = string delegate(string);

struct LayoutConfig {
  string description;
  string mapping;
  string xmlFile;
  string ignorePattern;
  string skipField;

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
	 * Examples:
	 * --------------
	 * auto conf = new Setting();
	 * --------------
	 */
	this() {

    // YAML settings file location is OS-dependent
    version(linux) {
      _rbfhome = environment["HOME"] ~ "/.rbf/";
      auto settingsFile = _rbfhome ~ "rbf.yaml";
    }
    version(win64) {
      _rbfhome = environment["APPDATA"];
      auto string settingsFile = _rbfhome ~ `\local\rbf\rbf.yaml`;
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
    if ("ignorePattern" in _document["layout"][layoutName])
      conf.ignorePattern = _document["layout"][layoutName]["ignorePattern"].as!string;

    if ("skipField" in _document["layout"][layoutName])
      conf.skipField     = _document["layout"][layoutName]["skipField"].as!string;

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
