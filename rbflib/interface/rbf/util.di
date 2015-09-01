// D import file generated from 'source/util.d'
module rbf.util;
import std.stdio;
import std.file;
import std.string;
import std.process;
import std.json;
import std.conv;
import std.path;
import std.typecons;
struct CommandLineOption
{
	string inputFileName;
	string outputFileName;
	string inputFormat;
	string outputFormat;
	string conditionFile;
}
enum mapperType 
{
	STRING_MAPPER,
	VARIABLE_MAPPER,
}
class RBFConfig
{
	private 
	{
		string _structureName;
		string _xmlStructure;
		alias Slice = Tuple!(int, int);
		mapperType _mappingType;
		string _constantMapping;
		Slice[] _sliceMapping;
		string _ignorePattern;
		public 
		{
			this(in string name, JSONValue tag);
			@property string xmlStructure();
			@property string ignorePattern();
			string record_identifier(string x);
			override string toString();
		}
	}
}
class Config
{
	private 
	{
		JSONValue[string] document;
		RBFConfig[string] conf;
		public 
		{
			this();
			RBFConfig opIndex(string rbfFormat);
		}
	}
}
