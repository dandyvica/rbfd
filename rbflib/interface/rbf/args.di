// D import file generated from 'source/args.d'
module rbf.args;
import std.stdio;
import std.file;
import std.string;
import std.process;
import std.getopt;
import std.regex;
import std.algorithm;
import std.path;
import rbf.conf;
import rbf.filter;
class CommandLineOption
{
	private 
	{
		string _inputFileName;
		string _outputFileName;
		string _outputDirectoryName;
		string _inputFormat;
		string _outputFormat = "txt";
		string _filterFile;
		Filter _filter;
		string _restrictionFile;
		string[][string] _fieldNames;
		public 
		{
			this(string[] argv);
			@property string inputFileName();
			@property string outputFileName();
			@property string inputFormat();
			@property string outputFormat();
			@property bool isRestriction();
			@property bool isFilter();
			@property string[][string] fieldNames();
			@property Filter filter();
			private string[][string] _readRestrictionFile(in string filename);
		}
	}
}
