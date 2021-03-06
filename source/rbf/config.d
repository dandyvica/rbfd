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
import std.exception;

import rbf.errormsg;
import rbf.log;
import rbf.nameditems;
import rbf.layout;

// helper function to print out members values of a struct
void printMembers(T)(T v)
{
	foreach (member; FieldNameTuple!T)
	{
		mixin("logger.info(LogType.FILE, \"%-50.50s : <%s>\", \"" ~ T.stringof ~ "." ~ member ~ "\", v." ~ member ~ ");");
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
version(OSX) 
{
    immutable xmlSettings = ".rbf/" ~ xmlSettingsFile;
}

// settings defaults
immutable SQL_DEFAULT_INSERT_POOL         = "3000";
immutable SQL_DEFAULT_GROUPED_INSERT_POOL = "100";

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
alias LayoutList = NamedItemsContainer!(SettingCore, false);

// holds definition of output format features
struct OutputConfiguration 
{
    string name;		          /// name of the output format (e.g.: "txt")
    string outputDirectory;		  /// location of output file
    string outputFileExtension;   /// file extension specific to output format

    string fieldSeparator;	      /// field separator char for text output format
    string lineSeparator;         /// line separator char for text output format
    bool fieldDescription;	      /// print field description if true

    bool useAlternateName;        /// use field name followed by its occurence
    string alternateNameFmt;      /// format to use when formatting alternate name

    Orientation orientation;      /// whether print by row or colums

    string templateFile;          /// template file when using output mode temp

    bool useRawValue;            /// true if we want to use raw values instead of stripped values

    // SQL specific
    struct
    {
        size_t sqlInsertPool;     /// used to group INSERTs into a single SQL transaction
        size_t sqlGroupedInsertPool;    /// used to group INSERTs into a single INSERT transaction
        string sqlPreFile;        /// name of the SQL file containing statements run before inserting data
        string sqlPostFile;       /// name of the SQL file containing statements run after inserting data
        //bool addDataSource;       /// whether the input file name is added as a source for data in SQL output
        string connectionString;  /// PostgreSQL connection string
    }
}
alias OutputList = NamedItemsContainer!(OutputConfiguration, false);

/***********************************
	* class for reading XML definition file
 */
class ConfigFromXMLFile 
{

private:
	LayoutList _layoutList;		/// list of all settings i.e all layout configuration (path, etc)
	OutputList _outputList;		/// list of all output formats

public:

    string logFileName;             /// where we'll write all log statements

	/**
	 * read the XML configuraimport rbf.xml file configuration file
	 */
	this(string xmlConfigFile = "") 
    {
        // define new container for layouts and formats
        _layoutList = new LayoutList("layouts");
        _outputList = new OutputList("outputs");

        // settings file depending on whether we found the file in the current directory,
        // given by an environment variable, or to a fixed location based on the OS type
        string settingsFile;

        // if file name is passed as an argument to the ctor, take it or otherwise try possible locations
        if (xmlConfigFile != "")
        {
            Log.console(Message.MSG071, xmlConfigFile); 
            settingsFile = xmlConfigFile;
        }
        else
        {
            settingsFile = _getConfigFileName();
        }

        // get settings file path
        auto settingsFilePath = dirName(settingsFile) ~ "/";

        // ensure file exists
        enforce(exists(settingsFile), Message.MSG004.format(settingsFile));

        // open XML settings file and load it into a string
        string s = cast(string)std.file.read(settingsFile);

        // create a new XML parser
        auto xml = new DocumentParser(s);

        // read <log> definition tag to extract log file name
        xml.onStartTag["log"] = (ElementParser xml)
        {
            // save global config and create the log handler
            logFileName = xml.tag.attr.get("path", "./rbf.log");

            // manage cases of absolute and relative path
            if (!isAbsolute(logFileName))
            {
                logFileName = settingsFilePath ~ logFileName;
            }
            logger = Log(this.logFileName);
        };

        // read <layout> definition tag to build the container of all layouts
        xml.onStartTag["layout"] = (ElementParser xml)
        {
            // we need to check whether the layout physical file is named as an absolute file path or relative
            // if relative, prepend with the directory of the settings file
            // it absolute, juste use it
            auto layoutFilePath = xml.tag.attr["file"].idup;
            if (!isAbsolute(layoutFilePath))
            {
                layoutFilePath = settingsFilePath ~ layoutFilePath;
            }

            // save layout metadata
            this._layoutList ~= SettingCore(
                    xml.tag.attr["name"],
                    xml.tag.attr["description"],
                    layoutFilePath,                    /// this is where the layout definition file is found
                    );
        };

        // read <output> definition tag to build the container of all outputs
        // what we call output is a type of external formatted data and is generally an export format
        xml.onStartTag["output"] = (ElementParser xml)
        {
            // manage attributes
            auto fdesc = xml.tag.attr.get("addFieldDescription", "false");

            // save layout metadata
            OutputConfiguration of;

            with (xml.tag)
            {
                // save common attributes
                of.name                 = attr["name"];
                of.outputDirectory      = attr.get("outputDirectory", "");
                of.fieldDescription     = to!bool(attr.get("addFieldDescription", "false"));
                of.useAlternateName     = to!bool(attr.get("useAlternateName", "false"));
                of.alternateNameFmt     = attr.get("alternateNameFormat", "%s(%d)");
                of.outputFileExtension  = attr.get("extension", to!string(of.name));

                // save text attributes
                of.fieldSeparator = attr.get("fieldSeparator", "|");
                of.lineSeparator  = attr.get("lineSeparator", "");

                // save HTML attributes
                of.orientation = to!Orientation(attr.get("orientation", "horizontal"));

                // save SQL attributes
                of.sqlInsertPool        = to!size_t(attr.get("insertPool", SQL_DEFAULT_INSERT_POOL));
                of.sqlGroupedInsertPool = to!size_t(attr.get("insertChunk", SQL_DEFAULT_GROUPED_INSERT_POOL));
                //of.addDataSource        = to!bool(attr.get("addSource", "false"));
                of.connectionString     = attr.get("connexionString", "");

                // save temp attributes
                of.templateFile = attr.get("templateFile", "rbf.template");

            }
            this._outputList ~= of;
        };

        // real parsing of the XML tags
        xml.parse();

        // log info in configuration file
        logger.info(LogType.FILE, Message.MSG027, settingsFile);

    }

    /// list all possible layouts
    void listLayouts()
    {
        _layoutList.each!(s => writefln(Message.MSG099, s.name, s.description, s.file));
    }


	@property LayoutList layoutList() { return _layoutList; }
	@property OutputList outputList() { return _outputList; }

private:
        
    // return the name of the configuration file with different methods
    string _getConfigFileName() 
    {

        // settings file
        string settingsFile;

        // test if env variable is set and if any, it's poiting on the settings file
        // location
        auto rbfconf = environment.get(xmlSettingsFileEnvVar, "");
        if (rbfconf != "") 
        {
            Log.console(Message.MSG067, rbfconf, xmlSettingsFileEnvVar);
            return rbfconf;
        }

        // otherwise, first possible location is current directory
        auto suspectedSettingsFile = buildNormalizedPath(getcwd, xmlSettingsFile);
        if (exists(suspectedSettingsFile)) 
        {
            Log.console(Message.MSG069, suspectedSettingsFile); 
            return suspectedSettingsFile;
        }
        // or path given by an env variable
        else 
        {
            // last possible location is OS-dependent
            string _rbfhome;
            version(linux) 
            {
                _rbfhome = environment["HOME"];
                settingsFile = _rbfhome ~ "/" ~ xmlSettings;
            }
            version(OSX) 
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

        Log.console(Message.MSG070, settingsFile); 
        return settingsFile;

    }

}
///
unittest {
    writefln("\n========> testing %s", __FILE__);
    auto c = new ConfigFromXMLFile("./test/config.xml");

    assert(c.layoutList["A"].name == "A");
    assert(c.layoutList["B"].description == "Desc B");
    assert(c.layoutList["C"].file.canFind("layout/c.xml"));
    assert(c.layoutList["world"].file.canFind("test/world_data.xml"));

    assert(c.outputList["txt"].name == "txt");
    assert(c.outputList["txt"].outputDirectory == "/tmp/");
    assert(c.outputList["txt"].fieldSeparator == "*");
    assert(!c.outputList["txt"].fieldDescription);

    writefln("********> end test %s\n", __FILE__);
}
