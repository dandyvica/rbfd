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
	public 
	{
		string inputFileName;
		string inputLayout;
		string outputFormat = "txt";
		string outputFileName;
		string fieldFilterFile;
		string recordFilterFile;
		string pgmVersion;
		bool verbose = false;
		Filter filteredRecords;
		string[][string] filteredFields;
		ulong samples;
		public 
		{
			this(string[] argv);
			@property bool isFieldFilterSet();
			@property bool isRecordFilterSet();
			void printOptions();
			private string[][string] _readRestrictionFile(in string filename);
		}
	}
}
