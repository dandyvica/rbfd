// D import file generated from 'source/util.d'
import std.stdio;
import std.file;
import std.string;
import std.process;
import std.json;
import std.conv;
struct CommandLineOption
{
	string inputFileName;
	string outputFileName;
	string outputMode;
	string inputFormat;
	string conditionFile;
}
class Config
{
	public 
	{
		immutable string xmlStructure;
		immutable string ignorePattern;
		immutable string envJSON = "RBFCONF";
		this(in string inputFormat);
	}
}
