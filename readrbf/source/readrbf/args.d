module args;

import std.stdio;
import std.file;
import std.string;
import std.process;
import std.getopt;
import std.regex;
import std.algorithm;
import std.path;
import std.exception;
import std.traits;
import std.conv;
import std.typecons;

import rbf.errormsg;
import rbf.recordfilter;
import rbf.options;
import rbf.writers.writer : OutputFormat;

immutable helpString = import("help.txt");
immutable authorString = import("author.txt");
immutable IAformat = "%-50.50s : ";

// useful mixin to generate input
template GenInput(string input)
{
    const char[] GenInput = `writef(IAformat, "` ~ input ~ `".leftJustify(50,'.')); input = readln();`;
}

// list of all command line parameters. The user defined attribute
// is the command line option. To add another option, just add it here
struct CommandLineArgument 
{
	@("i") @(config.required) string inputFileName;         /// input file name to parse
	@("l") @(config.required) string inputLayout;		    /// input file layout
	@("o") OutputFormat outputFormat = OutputFormat.txt;	/// output format HTML, TXT, ...
	@("of") string givenOutputFileName;		                /// name of the final converted file when given in the command line

	@("f") string fieldFilterFile;			               	/// if any, name of the field filter file
	@("ff") string fieldFilter;				                /// if any, list of records/fields to filter out

	@("r") string recordFilterFile;			                /// if any, name of the record filter file
	@("fr") string recordFilter;			                /// if any, name of the record filter file
    
    @("patch") string fieldsToPatch;                        /// list of fields to patch

	@("fl") string lineFilter;				                /// if any, define a regex to match lines

	@("v") bool bVerbose;					                /// if true, print out lots of data
	@("b") bool bJustRead;					                /// if true, don't write data
	@("p") bool bProgressBar;                               /// print out read record progress bar
	@("c") bool bCheckLayout;				                /// if true, try to validate layouy by checking length
	@("O") bool stdOutput;					                /// if true, print to standard output instead of file
	@("br") bool bBreakRecord;  			                /// if true, break records into individual sub-records
	@("check") bool bCheckPattern;  		                /// if true, check if field values are matching pattern
    @("stats") bool bDetailedStats;                         /// if true, print out detailed statistics on file at the end of conversion         

	@("s") ulong samples;					                /// limit to n first lines (n == samples)
    @("ua") bool bUseAlternateNames;                        /// in case of field duplication, append field name with index

    //@("") bool bAppendMode;                               /// overwrite the output file
    @("dup") bool bPrintDuplicatedPattern;                  /// write out duplicated patterns for each record

    @("conf") string cmdlineConfigFile;                     /// we can also provide configuration file from command line

    @("presql") string sqlPreFile;                          /// name of the SQL statement file to run after creating tables but 
                                                            /// before starting to insert data

    @("postsql") string sqlPostFile;                        /// name of the SQL statement file to run after inserting data
}

/***********************************
 * This class is holding command line arguments
 */
struct CommandLineOption {

public:

    CommandLineArgument options;                        /// list of arguments
	string filteredFields;				                /// if any list of fields to filter out
	RecordFilter filteredRecords;                       /// if any, list of clauses to filter records
	string outputFileName;		                		/// name of the final converted file
    auto possibleValues = [ EnumMembers!OutputFormat ]; /// list all possible layouts

public:
/***********************************
 * Process command line arguments
 */
 	this(string[] argv) {

		// print-out help
		if (argv.length == 1)
		{
            //_interactiveMode();
            _printHelp();
		}
        else if (argv.length == 2 && argv[1] == "-h")
        {
            _printHelp();
        }
        // deamon mode
        else
        {
            try 
            {
                // read command line arguments and fetch values in options struct
                processCommandLineArguments!CommandLineArgument(argv, options);
            }
            /*
            catch (ConvException e) 
            {
                stderr.writefln(msg043, possibleValues);
                core.stdc.stdlib.exit(2);
            }
            catch (GetOptException e)
            {
                stderr.writefln(MSG043, possibleValues);
                core.stdc.stdlib.exit(2);
            }
            */
            catch (Exception e) 
            {
                writefln("error: %s", e.msg);
                core.stdc.stdlib.exit(2);
            }
        }

        // break record option is not compatible with some output formats
        if (options.bBreakRecord)
        {
            if (options.outputFormat != OutputFormat.txt && options.outputFormat != OutputFormat.box)
            {
                stderr.writefln(MSG044);
                core.stdc.stdlib.exit(3);
            }
        }

		// if a filter file is selected, use it. Same for field filter entered in the command line
		// append the suffix
		if (options.fieldFilterFile != "") 
        {
			enforce(exists(options.fieldFilterFile), MSG041.format(options.fieldFilterFile));
			filteredFields = cast(string)std.file.read(options.fieldFilterFile);
		} else if (options.fieldFilter != "") 
        {
			filteredFields = options.fieldFilter;
		}

		// if record file filter or record filter is specified, load conditions
		if (options.recordFilterFile != "") 
        {
            // file should exist though
			enforce(exists(options.recordFilterFile), MSG042.format(options.recordFilterFile));
			filteredRecords = new RecordFilter(cast(string)std.file.read(options.recordFilterFile));
		} 
        else if (options.recordFilter != "") 
        {
			filteredRecords = new RecordFilter(options.recordFilter, ";");
		}

	}

	@property bool isFieldFilterFileSet()  { return options.fieldFilterFile != ""; }
	@property bool isFieldFilterSet()      { return options.fieldFilter != ""; }
	@property bool isRecordFilterFileSet() { return options.recordFilterFile != ""; }
	@property bool isRecordFilterSet()     { return options.recordFilter != ""; }

    /*
    void _interactiveMode()
    {
        string input;

        mixin(GenInput!("Input file name (mandatory)"));
        inputFileName    = input.strip;
        inputFileName    = inputFileName.replace("'","");

        mixin(GenInput!("Layout name (mandatory)"));
        inputLayout      = input.strip;

        mixin(GenInput!("Output format (optional but defaulted to: txt)"));
        if (input.strip == "")
        {
            outputFormat = OutputFormat.txt;
        }
        else
        {
            try
            {
                outputFormat = to!OutputFormat(input.strip);
            }
            catch (ConvException e) 
            {
                stderr.writefln(MSG043, possibleValues);
                core.stdc.stdlib.exit(2);
            }
        }

        mixin(GenInput!("Field filter file (optional)"));
        fieldFilterFile  = input.strip;

        mixin(GenInput!("Field filter (optional)"));
        fieldFilter      = input.strip;

        mixin(GenInput!("Record filter file (optional)"));
        recordFilterFile = input.strip;

        mixin(GenInput!("Record filter (optional)"));
        recordFilter     = input.strip;

        //bVerbose = true;
        bProgressBar = true;
    }
    */

    void _printHelp(string msg="")
    {
        writeln(helpString.format(possibleValues));
        writeln(authorString);
        writefln("Compiled on %s with %s version %d", __DATE__, __VENDOR__, __VERSION__);
        if (msg != "") stderr.writefln("error: %s", msg);
        core.stdc.stdlib.exit(1);
    }

}
///
unittest {
	writeln("========> testing ", __FILE__);

	auto argv = ["", "-i", "foo.input"];
	assertThrown(new CommandLineOption(argv));

	argv = ["", "-l", "xml"];
	assertThrown(new CommandLineOption(argv));

	argv = ["", "-i", "foo.input", "-l", "xml"];
	auto c = new CommandLineOption(argv);
	assert(c.inputFileName == "foo.input");
	assert(c.inputLayout == "xml");

	core.stdc.stdlib.exit(2);
}
