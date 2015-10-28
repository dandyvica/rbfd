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
import std.traits;

import rbf.errormsg;
import rbf.nameditems;
import rbf.layout;

// helper function to print out members values of a struct
void printMembers(T)(T v)
{
	foreach (member; FieldNameTuple!T)
	{
		mixin("stderr.writefln(\"%-50.50s : <%s>\", \"" ~ T.stringof ~ "." ~ member ~ "\", v." ~ member ~ ");");
	}
}

/// configuration file name
version(linux) {
immutable xmlSettings = ".rbf/rbf.xml";
}
version(Win64) {
immutable xmlSettings = `\local\rbf\rbf.xml`;
}

/*********************************************
 * Orientation for printing out data:
 * 		horizontal: values per row
 * 		vertical: values per colmun
 */
enum Orientation { horizontal, vertical }

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


struct SettingCore {
	mixin  LayoutCore;
}
alias LayoutDir = NamedItemsContainer!(SettingCore, false);

struct OutputFeature {
	string name;		 	        /// name of the outpout format (e.g.: "txt")
	string outputDir;		      /// location of output file
	string fsep;		          /// field separator char for text output format
	string lsep;		          /// line separator char for text output format
	Orientation orientation;	/// whether print by row or colums
  string zipper;            /// name and path of the zipper executable
	bool fielddesc;		        /// print field description if true
	bool useAlternateName;    /// use field name followed by its occurence
  string alternateNameFmt;  /// format to use when formatting alternate name
}
alias OutputDir = NamedItemsContainer!(OutputFeature, false);

/***********************************
	* class for reading XML definition file
 */
//class Setting : NamedItemsContainer!(SettingCore, false, SettingMeta) {
class Setting {

private:
	LayoutDir _layoutDirectory;		/// list of all settings
	OutputDir _outputDirectory;		/// list of all output formats

public:
	/**
	 * read the XML configuraimport rbf.xml file configuration file
	 */
	this(string xmlConfigFile = "") {

		// define new container for layouts and formats
		_layoutDirectory = new LayoutDir("layouts");
		_outputDirectory = new OutputDir("outputs");

    // settings file
    string settingsFile;

    // if file name is passed, take it or otherwise try possible locations
		settingsFile = (xmlConfigFile != "") ? xmlConfigFile : _getConfigFileName();

		// get settings path
		auto settingsFilePath = dirName(settingsFile) ~ "/";

		// ensure file exists
		std.exception.enforce(exists(settingsFile), MSG004.format(settingsFile));

    // open XML file and load it into a string
		string s = cast(string)std.file.read(settingsFile);

		// create a new parser
		auto xml = new DocumentParser(s);

    // read <layout> definition tag
		xml.onStartTag["layout"] = (ElementParser xml)
		{
			// save layout metadata
      this._layoutDirectory ~= SettingCore(
        xml.tag.attr["name"],
        xml.tag.attr["description"],
        settingsFilePath ~ xml.tag.attr["file"],
      );
		};

    // read <output> definition tag
		xml.onStartTag["output"] = (ElementParser xml)
		{
			// manage attributes
			auto fdesc = xml.tag.attr.get("fdesc", "false");

			// save layout metadata
      this._outputDirectory ~= OutputFeature(
        xml.tag.attr["name"],
        xml.tag.attr.get("outputDir", ""),
        xml.tag.attr.get("fsep", "|"),
        xml.tag.attr.get("lsep", ""),
        to!Orientation(xml.tag.attr.get("orientation", "horizontal")),
        xml.tag.attr.get("zipper", ""),
        (fdesc == "true") ? true : false,
        to!bool(xml.tag.attr.get("useAlternateName", "false")),
        xml.tag.attr.get("alternateNameFmt", "%s(%d)"),
      );
		};

    // real parsing
		xml.parse();

  }

	@property LayoutDir layoutDir() { return _layoutDirectory; }
	@property OutputDir outputDir() { return _outputDirectory; }

private:
  string _getConfigFileName() {

    // settings file
    string settingsFile;

    // test if env variable is set
		auto rbfconf = environment.get("RBFCONF", "");
    if (rbfconf != "") return rbfconf;

    // otherwise, first possible location is current directory
    if (exists(getcwd ~ xmlSettings)) {
      settingsFile = getcwd ~ xmlSettings;
    }
    else {
      // XML settings file location is OS-dependent
      string _rbfhome;
      version(linux) {
        _rbfhome = environment["HOME"];
        settingsFile = _rbfhome ~ "/" ~ xmlSettings;
      }
      version(Win64) {
        _rbfhome = environment["APPDATA"];
         settingsFile = _rbfhome ~ xmlSettings;
      }
    }

    return settingsFile;

  }

}
///
unittest {
	writeln("========> testing ", __FILE__);
	auto c = new Setting("./test/config.xml");

  assert(c.layoutDir["A"].name == "A");
  assert(c.layoutDir["B"].description == "Desc B");
  assert(c.layoutDir["C"].file.canFind("layout/c.xml"));
	assert(c.layoutDir["world"].file.canFind("test/world_data.xml"));

  assert(c.outputDir["txt"].name == "txt");
  assert(c.outputDir["txt"].outputDir == "/tmp/");
  assert(c.outputDir["txt"].fsep == "*");
  assert(!c.outputDir["txt"].fielddesc);

  assert(c.outputDir["xlsx"].zipper == "/usr/bin/zip");
}
