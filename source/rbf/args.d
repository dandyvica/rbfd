module rbf.args;

import core.stdc.stdlib;
import std.algorithm;
import std.ascii;
import std.conv;
import std.exception;
import std.file;
import std.getopt;
import std.path;
import std.process;
import std.regex;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;

import rbf.errormsg;
import rbf.recordfilter;
import rbf.layout;
import rbf.log;
import rbf.options;
import rbf.convert;
import rbf.writers.writer : OutputFormat;

// import of some static text
immutable helpString = import("help.txt");
immutable authorString = import("author.txt");
immutable IAformat = "%-50.50s : ";

// useful mixin to generate input
template GenInput(string input)
{
    const char[] GenInput = `writefln(IAformat, "` ~ input ~ `".leftJustify(50,'.')); input = readln();`;
}

// list of all command line parameters. The user defined attribute
// is the command line option. To add another option, just add it here
struct CommandLineArgument 
{
	@("b") bool bJustRead;					                /// if true, don't write data
	@("br") bool bBreakRecord;  			                /// if true, break records into individual sub-records
    @("buildxml") string xmlConfigFile;                     /// creation layout file for text file
	@("check") bool bCheckPattern;  		                /// if true, check if field values are matching pattern
    @("conf") string cmdlineConfigFile;                     /// we can also provide configuration file from command line
    @("convert") string layoutFileToConvert;                /// name of the layout file to convert
    @("dup") bool bPrintDuplicatedPattern;                  /// write out duplicated patterns for each record
	@("f") string fieldFilterFile;			               	/// if any, name of the field filter file
	@("ff") string fieldFilter;				                /// if any, list of records/fields to filter out
	@("fl") string lineFilter;				                /// if any, define a regex to match lines
    @("format") Format convFormat = Format.html;            /// output format when converting a layout                    
	@("fr") string recordFilter;			                /// if any, name of the record filter file
	@("i") string inputFileName;                            /// input file name to parse
	@("l") string inputLayout;		                        /// input file layout
	@("o") OutputFormat outputFormat = OutputFormat.txt;	/// output format HTML, TXT, ...
	@("of") string givenOutputFileName;		                /// name of the final converted file when given in the command line
	@("out") bool stdOutput;					            /// if true, print to standard output instead of file
	@("p") bool bProgressBar;                               /// print out read record progress bar
    @("patch") string fieldsToPatch;                        /// list of fields to patch
    @("postsql") string sqlPostFile;                        /// name of the SQL statement file to run after inserting data
    @("presql") string sqlPreFile;                          /// name of the SQL statement file to run after creating tables but 
	@("r") string recordFilterFile;			                /// if any, name of the record filter file
    @("raw") bool useRawValue;                              /// use raw string values instead of stripped values
	@("s") ulong samples;					                /// limit to n first lines (n == samples)
    @("stats") bool bDetailedStats;                         /// if true, print out detailed statistics on file at the end of conversion         
    @("strict") bool strictRun;                             /// exit if record is not found in layout
    //@("tempfile") string templateFile;                      /// when using the temp output mode, using this file as template
    @("template") string templateFile;
	@("trigger") string trigger;				            /// if any, record name which triggers write for templates
    @("ua") bool bUseAlternateNames;                        /// in case of field duplication, append field name with index
	@("v") bool bVerbose;					                /// if true, print out lots of data
	@("validate") string layoutFile;				        /// used to validate the layout XML file
}

/***********************************
 * This class is holding command line arguments
 */
struct CommandLineOption 
{

public:

    CommandLineArgument cmdLineArgs;                    /// list of arguments
	string filteredFields;				                /// if any list of fields to filter out
	RecordFilter filteredRecords;                       /// if any, list of clauses to filter records
	string outputFileName;		                		/// name of the final converted file
    auto possibleValues = [ EnumMembers!OutputFormat ]; /// list all possible layouts

public:
/***********************************
 * Process command line arguments
 */
 	this(string[] argv) 
    {

        //--------------------------------------------------------------------
        // manage all different cases
        //--------------------------------------------------------------------
        try 
        {
            // read command line arguments and fetch values in options struct
            processCommandLineArguments!CommandLineArgument(argv, cmdLineArgs);
        }
        catch (Exception e) 
        {
            writefln("error: %s", e.msg);
            exit(2);
        }

        //--------------------------------------------------------------------
		// readrbf
        //--------------------------------------------------------------------
		if (argv.length == 1)
		{
            _printHelp();
            exit(1);
		}



        // break record option is not compatible with some output formats
        if (cmdLineArgs.bBreakRecord)
        {
            if (cmdLineArgs.outputFormat != OutputFormat.txt && cmdLineArgs.outputFormat != OutputFormat.box)
            {
                Log.console(Message.MSG044);
                exit(3);
            }
        }

		// if a filter file is selected, use it. Same for field filter entered in the command line
		// append the suffix
		if (cmdLineArgs.fieldFilterFile != "") 
        {
			enforce(exists(cmdLineArgs.fieldFilterFile), Message.MSG041.format(cmdLineArgs.fieldFilterFile));
			filteredFields = cast(string)std.file.read(cmdLineArgs.fieldFilterFile);
		} 
        else if (cmdLineArgs.fieldFilter != "") 
        {
			filteredFields = cmdLineArgs.fieldFilter;
		}

		// if record file filter or record filter is specified, load conditions
		if (cmdLineArgs.recordFilterFile != "") 
        {
            // file should exist though
			enforce(exists(cmdLineArgs.recordFilterFile), Message.MSG042.format(cmdLineArgs.recordFilterFile));
			filteredRecords = new RecordFilter(cast(string)std.file.read(cmdLineArgs.recordFilterFile));
		} 
        else if (cmdLineArgs.recordFilter != "") 
        {
			filteredRecords = new RecordFilter(cmdLineArgs.recordFilter, ";");
		}

	}

    // useful helpers
	@property bool isFieldFilterFileSet()  { return cmdLineArgs.fieldFilterFile != ""; }
	@property bool isFieldFilterSet()      { return cmdLineArgs.fieldFilter != ""; }
	@property bool isRecordFilterFileSet() { return cmdLineArgs.recordFilterFile != ""; }
	@property bool isRecordFilterSet()     { return cmdLineArgs.recordFilter != ""; }

    // start interactive mode to prompt data from user
    void _interactiveMode()
    {
        string input;

        // prompt for input file
        mixin(GenInput!("Input file name (mandatory)"));
        cmdLineArgs.inputFileName    = input.strip;
        cmdLineArgs.inputFileName    = cmdLineArgs.inputFileName.replace("'","");
        writefln("input file is <%s>", cmdLineArgs.inputFileName);

        // prompt for input layout
        mixin(GenInput!("Layout name (mandatory)"));
        cmdLineArgs.inputLayout      = input.strip;

        // prompt for output format
        writefln("Output format, possible value are: %s", possibleValues);
        input = readln();
        if (input.strip == "")
        {
            cmdLineArgs.outputFormat = OutputFormat.txt;
        }
        else
        {
            try
            {
                cmdLineArgs.outputFormat = to!OutputFormat(input.strip);
            }
            catch (ConvException e) 
            {
                stderr.writefln(Message.MSG043, possibleValues);
                exit(2);
            }
        }

        // optional 
        mixin(GenInput!("Field filter file (optional)"));
        cmdLineArgs.fieldFilterFile  = input.strip;

        mixin(GenInput!("Field filter (optional)"));
        cmdLineArgs.fieldFilter      = input.strip;

        mixin(GenInput!("Record filter file (optional)"));
        cmdLineArgs.recordFilterFile = input.strip;

        mixin(GenInput!("Record filter (optional)"));
        cmdLineArgs.recordFilter     = input.strip;

        //bVerbose = true;
        cmdLineArgs.bProgressBar = true;
    }

    // just print out help message with all possible options
    void _printHelp(string msg="")
    {
        writeln(helpString.format(possibleValues));
        writeln(authorString);
        writefln("Compiled on %s with %s version %d", __DATE__, __VENDOR__, __VERSION__);
        if (msg != "") stderr.writefln("error: %s", msg);
        exit(1);
    }

}
///
unittest {
    writefln("\n========> testing %s", __FILE__);

	auto argv = ["", "-i", "foo.input"];
	//assertThrown(new CommandLineOption(argv));

	argv = ["", "-l", "xml"];
	//assertThrown(new CommandLineOption(argv));

	argv = ["", "-i", "foo.input", "-l", "isr", "-p"];
	auto c = new CommandLineOption(argv);
	assert(c.cmdLineArgs.inputFileName == "foo.input");
	assert(c.cmdLineArgs.inputLayout == "isr");

    writefln("********> end test %s\n", __FILE__);
}
