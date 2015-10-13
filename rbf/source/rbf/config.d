module rbf.config;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.process;
import std.xml;
import std.conv;
import std.path;
import std.typecons;
import std.algorithm;
import std.range;
import std.functional;
import std.regex;

import rbf.nameditems;
import rbf.layout;

//alias RECORD_MAPPER = string delegate(string);

/// configuration file name
immutable xmlSettings = "rbf.xml";

/***********************************
	* struct for describing layout metadata
 */
/*
struct LayoutConfig {
  string description;         /// a short description of the layout
  string mapping;             /// how to map a read line to a record object?
  string xmlFile;             /// XML definition of layout
  Regex!char ignoreRecord;    /// in some case, we need to get rid of some lines
  string skipField;           /// in some cases, don't take into account some fields
  string layoutType;          /// what kind of layout is it?

  // mapper is used to find a record name from a line read from file
  RECORD_MAPPER mapper;
}*/

struct SettingMeta {
  string zipper;      /// name and path of the zipper excutable
}

/***********************************
	* class for reading XML definition file
 */
class Setting : NamedItemsContainer!(LayoutMeta, false, SettingMeta) {

public:
	/**
	 * read the YAML configuration file
	 *
   * Params:
	 * 	xmlConfigFile = optional file configuration file
	 */
	this(string xmlConfigFile = "") {

    // settings file
    string settingsFile;

    // if file is passed, take it
    if (xmlConfigFile != "") {
      settingsFile = xmlConfigFile;
    }
    else {
      // first possible location is current directory
      if (exists(getcwd ~ xmlSettings)) {
        settingsFile = getcwd ~ xmlSettings;
      }
      else {
        // YAML settings file location is OS-dependent
        string _rbfhome;
        version(linux) {
          _rbfhome = environment["HOME"] ~ "/.rbf/";
          settingsFile = _rbfhome ~ "rbf.xml";
        }
        version(win64) {
          _rbfhome = environment["APPDATA"];
           settingsFile = _rbfhome ~ `\local\rbf\rbf.xml`;
        }
      }
    }

		// ensure file exists
		std.exception.enforce(exists(settingsFile), "Settings file %s not found".format(settingsFile));

    // open XML file and load it into a string
		string s = cast(string)std.file.read(settingsFile);

		// create a new parser
		auto xml = new DocumentParser(s);

    // read <layout> definition tag
		xml.onStartTag["layout"] = (ElementParser xml)
		{
			// save layout metadata
      this ~= LayoutMeta(
        xml.tag.attr["name"],
        xml.tag.attr["description"],
        xml.tag.attr["file"],
        0,
        ""
      );
		};

    // read <zipper> definition tag
		xml.onStartTag["zipper"] = (ElementParser xml)
		{
			// save layout metadata
      version(linux) {
        if (xml.tag.attr["os"] == "linux") this.meta.zipper = xml.tag.attr["path"].dup;
writefln("<%s>", xml.tag.attr["path"]);
      }
      version(windows) {
        if (xml.tag.attr["os"] == "windows") this.meta.zipper = xml.tag.attr["path"];
      }
		};

    // real parsing
		xml.parse();

  }

}

///
unittest {
	auto c = new Setting("./test/config.xml");
writefln("<%s>", c.meta.zipper);
  assert(c.meta.zipper == "/usr/bin/zip");
  assert(c["A"].name == "A");
  assert(c["B"].description == "Desc B");
  assert(c["C"].file == "layout/c.xml");
}
