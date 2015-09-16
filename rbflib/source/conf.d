module rbf.conf;

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

static Config configSettings;

/***********************************
 * the mapper is either a constant or a variable
 */
enum mapperType { STRING_MAPPER, VARIABLE_MAPPER }
alias MAPPER = string delegate(string);

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
	string _ignorePattern;  	/// if any, ignore those lines when reading
  MAPPER _record_mapper;    /// callback called to indentify one record
  string[] _skipFieldList;  /// optional field list to no consider when reading

  char[] _recordName;

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

    // ignore pattern might not be found
		if ("skip" in tag) {
//writeln(tag["skip"].str);
			_skipFieldList = tag["skip"].str.split(",");
		}
//writeln(_skipField);

		// get mapping
    // whenever our mapping is just one string, simple case
		if ("constant" in tag["mapping"]) {
			_mappingType = mapperType.STRING_MAPPER;
			_constantMapping = tag["mapping"]["constant"].str.dup;
      _record_mapper = &_string_mapper;
		}
    // otherwise, function is a concatenation of slices
		else if ("variable" in tag["mapping"]) {
			_mappingType = mapperType.VARIABLE_MAPPER;

			// slices are just an array of tuples
      auto _sliceLength = 0;
			foreach (slice; tag["mapping"]["variable"].str.split(",")) {
				// slice is like '0:2', so we need to extract 0 and 2
				auto bounds = slice.split(':');
				auto lower_bound = to!int(bounds[0]);
				auto upper_bound = to!int(bounds[1]);

        // in the meantime, calculate length of our final record name
        _sliceLength += (upper_bound - lower_bound);

				// and get slice from string
				_sliceMapping ~= Slice(lower_bound, upper_bound);
			}

      //writefln("_sliceLength = %s:%d ", name, _sliceLength);

      // as we now how munch our record name will occupy, we can allocate it
      _recordName = new char[_sliceLength];

      // we can refer to our callback
      _record_mapper = &_variable_mapper;

		}
		else
				throw new Exception("no constant or variable mapper defined for format %s".format(_structureName));
	}

	@property string xmlStructure() { return _xmlStructure; }
	@property string ignorePattern() { return _ignorePattern; }
	@property string[] skipFieldList() { return _skipFieldList; }
  string record_identifier(string x) { return _record_mapper(x); }


	override string toString() {
		return "<%s>: structure file=<%s>, ignore pattern=<%s>, mapping=<%s>"
			.format(_structureName, _xmlStructure, _ignorePattern, _sliceMapping);
	}

  /*
	string record_identifier(string x) {
		string result;

		// depending on type, return a constant or a list of values
		if (_mappingType == mapperType.STRING_MAPPER)
			result = _constantMapping;
		else if (_mappingType == mapperType.VARIABLE_MAPPER)
      result =  reduce!((a,b) => a ~= x[b[0]..b[1]])("", _sliceMapping);

    return result;
	}*/

private:
  string _string_mapper(string x) { return _constantMapping; }

  string _variable_mapper(string x) {
    ushort index = 0;
    foreach (s1; _sliceMapping) {
      foreach (s2; s1[0]..s1[1]) {
        _recordName[index++] = x[s2];
      }
    }
    return _recordName.idup;
  }

}

/***********************************
	* class for reading JSON property file
 */
class Config {
private:
	JSONValue[string] document;		/// tags as read from the JSON settings file
	RBFConfig[string] conf;				/// individual config for one XML structure

  string _zipper;               /// path/name of the excutable used tip zip .xlsx


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
					`\local\rbf\rbf.json`;
		}
		// ensure file exists
		std.exception.enforce(exists(settingsFile), "Settings file %s not found".format(settingsFile));

		// Ok, now read JSON
		auto jsonTags = to!string(read(settingsFile));
		document = parseJSON(jsonTags).object;

    // save location of zipper file
		version(linux) {
			_zipper = document["global"]["zipper"]["linux"].str;
		}
		version(win64) {
      _zipper = document["global"]["zipper"]["win64"].str;
		}

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

  @property string zipper() { return _zipper; }

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
