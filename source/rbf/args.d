module rbf.args;

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
import std.ascii;
import core.stdc.stdlib;

import rbf.errormsg;
import rbf.recordfilter;
import rbf.layout;
import rbf.log;
import rbf.options;
import rbf.convert;
import rbf.writers.writer : OutputFormat;
import rbf.builders.xmltextbuilder;

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
	@("i") string inputFileName;                            /// input file name to parse
	@("l") @(config.required) string inputLayout;		    /// input file layout
	@("o") OutputFormat outputFormat = OutputFormat.txt;	/// output format HTML, TXT, ...
	@("of") string givenOutputFileName;		                /// name of the final converted file when given in the command line

	@("f") string fieldFilterFile;			               	/// if any, name of the field filter file
	@("ff") string fieldFilter;				                /// if any, list of records/fields to filter out

	@("r") string recordFilterFile;			                /// if any, name of the record filter file
	@("fr") string recordFilter;			                /// if any, name of the record filter file
    
    @("patch") string fieldsToPatch;                        /// list of fields to patch

	@("fl") string lineFilter;				                /// if any, define a regex to match lines

	@("trigger") string trigger;				            /// if any, record name which triggers write for templates
    @("tempfile") string templateFile;                      /// when using the temp output mode, using this file as template


	@("v") bool bVerbose;					                /// if true, print out lots of data
	@("b") bool bJustRead;					                /// if true, don't write data
	@("p") bool bProgressBar;                               /// print out read record progress bar
	@("out") bool stdOutput;					            /// if true, print to standard output instead of file
	@("br") bool bBreakRecord;  			                /// if true, break records into individual sub-records
	@("check") bool bCheckPattern;  		                /// if true, check if field values are matching pattern
    @("stats") bool bDetailedStats;                         /// if true, print out detailed statistics on file at the end of conversion         

	@("s") ulong samples;					                /// limit to n first lines (n == samples)
    @("ua") bool bUseAlternateNames;                        /// in case of field duplication, append field name with index

    //@("") bool bAppendMode;                               /// overwrite the output file
    @("dup") bool bPrintDuplicatedPattern;                  /// write out duplicated patterns for each record

    @("conf") string cmdlineConfigFile;                     /// we can also provide configuration file from command line

    @("buildxml") string xmlConfigFile;                     /// we can also provide configuration file from command line

    @("presql") string sqlPreFile;                          /// name of the SQL statement file to run after creating tables but 
                                                            /// before starting to insert data

    @("postsql") string sqlPostFile;                        /// name of the SQL statement file to run after inserting data

	@("validate") string layoutFile;				        /// used to validate the layout XML file

    @("raw") bool useRawValue;                              /// use raw string values instead of stripped values

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

		// print-out help
		if (argv.length == 1)
		{
            _printHelp();
		}
        else if (argv.length == 2 && argv[1] == "-h")
        {
            _printHelp();
        }
        else if (argv.length == 2 && argv[1] == "--lazy")
        {
            _interactiveMode();
        }
        else if (argv.length == 3 && argv[1] == "--buildxml")
        {
            auto r = new RbfTextBuilder(argv[2]);
            r.processInputFile;
            exit(2);
        }
        else if (argv.length == 3 && argv[1] == "--validate")
        {
            // new log to stdout
            log = Log(stdout);
    		auto layout = new Layout(argv[2]);
			layout.validate;
            exit(2);
        }
        else if (argv[1] == "--convert" || argv[1] == "--format")
        {
            // specific options here
            struct CommandLineArgumentConvert 
            {
                @("convert") @(config.required) string layoutFileToConvert;  /// name of the layout file to convert
                @("format") @(config.required) Format convFormat = Format.html;             /// output format                     
                @("template") string templateFile;
            }
            CommandLineArgumentConvert convOptions;

            // new log to stdout
            log = Log(stderr);

            // process arguments
            processCommandLineArguments!CommandLineArgumentConvert(argv, convOptions);

            // check arguments
            if (convOptions.convFormat == Format.temp && convOptions.templateFile == "")
            {
                stderr.writeln(Message.MSG090);
            }
            else
            {
                // call conversion function
                convertLayout(convOptions.layoutFileToConvert,  convOptions.convFormat, convOptions.templateFile);
            }
            exit(2);
        }
        // deamon mode
        else
        {
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
        }

        // break record option is not compatible with some output formats
        if (cmdLineArgs.bBreakRecord)
        {
            if (cmdLineArgs.outputFormat != OutputFormat.txt && cmdLineArgs.outputFormat != OutputFormat.box)
            {
                stderr.writefln(Message.MSG044);
                exit(3);
            }
        }

		// if a filter file is selected, use it. Same for field filter entered in the command line
		// append the suffix
		if (cmdLineArgs.fieldFilterFile != "") 
        {
			enforce(exists(cmdLineArgs.fieldFilterFile), Message.MSG041.format(cmdLineArgs.fieldFilterFile));
			filteredFields = cast(string)std.file.read(cmdLineArgs.fieldFilterFile);
		} else if (cmdLineArgs.fieldFilter != "") 
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
	writeln("========> testing ", __FILE__);

	auto argv = ["", "-i", "foo.input"];
	assertThrown(new CommandLineOption(argv));

	argv = ["", "-l", "xml"];
	assertThrown(new CommandLineOption(argv));

	argv = ["", "-i", "foo.input", "-l", "xml"];
	auto c = new CommandLineOption(argv);
	assert(c.inputFileName == "foo.input");
	assert(c.inputLayout == "xml");

	exit(2);
}
