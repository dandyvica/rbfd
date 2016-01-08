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
import rbf.log;
import rbf.nameditems;
import rbf.layout;

// helper function to print out members values of a struct
void printMembers(T)(T v)
{
	foreach (member; FieldNameTuple!T)
	{
		mixin("log.log(LogLevel.INFO, \"%-50.50s : <%s>\", \"" ~ T.stringof ~ "." ~ member ~ "\", v." ~ member ~ ");");
	}
}

/// configuration file name
immutable xmlSettingsFile = "rbf.xml";
immutable xmlSettingsFileEnvVar = "RBF_CONF";
version(linux) 
{
    immutable xmlSettings = ".rbf/" ~ xmlSettingsFile;
}
version(Windows) 
{
    immutable xmlSettings = `\rbf\` ~ xmlSettingsFile;
}

// settings file

/*********************************************
 * Orientation for printing out data:
 * 		horizontal: values per row
 * 		vertical: values per colmun
 */
enum Orientation { horizontal, vertical }

/***********************************
	* struct for describing layout metadata
 */
struct SettingCore 
{
	mixin  LayoutCore;
}
alias LayoutDir = NamedItemsContainer!(SettingCore, false);

struct OutputFeature 
{
    string name;		      /// name of the output format (e.g.: "txt")
    string outputDir;		  /// location of output file
    string fsep;		      /// field separator char for text output format
    string lsep;		      /// line separator char for text output format
    Orientation orientation;  /// whether print by row or colums
    string zipper;            /// name and path of the zipper executable
    bool fielddesc;		      /// print field description if true
    bool useAlternateName;    /// use field name followed by its occurence
    string alternateNameFmt;  /// format to use when formatting alternate name
    ushort insertPool;        /// used to group INSERTs into a single transaction
    string outputExtension;   /// file extension specific to output format
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

    string logFileName;             /// where we'll write all log statements

	/**
	 * read the XML configuraimport rbf.xml file configuration file
	 */
	this(string xmlConfigFile = "") 
    {

        // define new container for layouts and formats
        _layoutDirectory = new LayoutDir("layouts");
        _outputDirectory = new OutputDir("outputs");

        // settings file depending on whether we found the file in the current directory,
        // given by an environment variable, or to a fixed location based on the OS type
        string settingsFile;

        // if file name is passed as an argument to the ctor, take it or otherwise try possible locations
        settingsFile = (xmlConfigFile != "") ? xmlConfigFile : _getConfigFileName();

        // get settings file path
        auto settingsFilePath = dirName(settingsFile) ~ "/";

        // ensure file exists
        std.exception.enforce(exists(settingsFile), MSG004.format(settingsFile));

        // open XML settings file and load it into a string
        string s = cast(string)std.file.read(settingsFile);

        // create a new XML parser
        auto xml = new DocumentParser(s);

        // read <log> definition tag to extract log file name
        xml.onStartTag["log"] = (ElementParser xml)
        {
            // save global config and create the log handler
            this.logFileName = xml.tag.attr.get("path", "./rbf.log");
            log = Log(this.logFileName);
        };

        // read <layout> definition tag to build the container of all layouts
        xml.onStartTag["layout"] = (ElementParser xml)
        {
            // save layout metadata
            this._layoutDirectory ~= SettingCore(
                    xml.tag.attr["name"],
                    xml.tag.attr["description"],
                    settingsFilePath ~ xml.tag.attr["file"],        /// this is where the layout definition file is found
                    );
        };

        // read <output> definition tag to build the container of all outputs
        // what we call output is a type of external formatted data and is generally an export format
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
                    to!ushort(xml.tag.attr.get("pool", "30")),
                    xml.tag.attr.get("extension", to!string(xml.tag.attr["name"])),
                    );
        };

        // real parsing of the XML tags
        xml.parse();

        // log info in configuration file
        log.log(LogLevel.INFO, MSG027, settingsFile);

    }

	@property LayoutDir layoutDir() { return _layoutDirectory; }
	@property OutputDir outputDir() { return _outputDirectory; }

private:
        
    // return the name of the configuration file with different methods
    string _getConfigFileName() 
    {

        // settings file
        string settingsFile;

        // test if env variable is set and if any, it's poiting on the settings file
        // location
        auto rbfconf = environment.get(xmlSettingsFileEnvVar, "");
        if (rbfconf != "") return rbfconf;

        // otherwise, first possible location is current directory
        auto suspectedSettingsFile = buildNormalizedPath(getcwd, xmlSettingsFile);
        if (exists(suspectedSettingsFile)) 
        {
            return suspectedSettingsFile;
        }
        else 
        {
            // last possible location is OS-dependent
            string _rbfhome;
            version(linux) 
            {
                _rbfhome = environment["HOME"];
                settingsFile = _rbfhome ~ "/" ~ xmlSettings;
            }
            version(Windows) 
            {
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
