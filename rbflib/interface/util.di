// D import file generated from 'source/util.d'
module rbf.util;
import std.stdio;
import std.file;
import std.string;
import std.process;
import std.json;
import std.conv;
import std.path;
struct CommandLineOption
{
	string inputFileName;
	string outputFileName;
	string outputMode;
	string inputFormat;
	string conditionFile;
}
enum mapperType 
{
	STRING_MAPPER,
	VARIABLE_MAPPER,
}
struct RBFConfig
{
	string xmlStructure;
	string[] sliceList;
	string ignorePattern;
	string record_identifier(string x);
}
class Config
{
	private 
	{
		JSONValue[string] tags;
		public 
		{
			this();
			RBFConfig opIndex(string rbfFormat);
		}
	}
}
