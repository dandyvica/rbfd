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

import rbf.errormsg;
import rbf.recordfilter;
import rbf.writers.writer : OutputFormat;

immutable helpString = import("help.txt");
immutable authorString = import("author.txt");
immutable IAformat = "%-50.50s : ";

// useful mixin to generate input
template GenInput(string input)
{
    const char[] GenInput = `writef(IAformat, "` ~ input ~ `".leftJustify(50,'.')); input = readln();`;
}



/***********************************
 * This class is holding command line arguments
 */
struct CommandLineOption {

public:
	string inputFileName;			                	/// input file name to parse
	string inputLayout;					                /// input file layout
	OutputFormat outputFormat = OutputFormat.txt;		/// output format HTML, TXT, ...
	string outputFileName;		                		/// name of the final converted file
	string givenOutputFileName;		                    /// name of the final converted file when given in the command line

	string fieldFilterFile;			                	/// if any, name of the field filter file
	string fieldFilter;					                /// if any, list of records/fields to filter out
	string filteredFields;				                /// if any list of fields to filter out

	string recordFilterFile;			                /// if any, name of the record filter file
	string recordFilter;				                /// if any, name of the record filter file
	RecordFilter filteredRecords;                       /// if any, list of clauses to filter records

	string lineFilter;					                /// if any, define a regex to match lines

	bool bVerbose;						                /// if true, print out lots of data
	bool bJustRead;						                /// if true, don't write data
	bool bProgressBar;                                  /// print out read record progress bar
	bool bCheckLayout;					                /// if true, try to validate layouy by checking length
	bool stdOutput;						                /// if true, print to standard output instead of file
	bool bBreakRecord;  			                    /// if true, break records into individual sub-records
	bool bCheckPattern;  				                /// if true, check if field values are matching pattern
    bool bDetailedStats;                                /// if true, print out detailed statistics on file at the end of conversion         

	ulong samples;					                    /// limit to n first lines (n == samples)
    bool bUseAlternateNames;                            /// in case of field duplication, append field name with index

    bool bAppendMode;                                   /// overwrite the output file
    bool bPrintDuplicatedPattern;                       /// write out duplicated patterns for each record

    string cmdlineConfigFile;                           /// we can also provide configuration file from command line

    string sqlPreFile;                                  /// name of the SQL statement file to run after creating tables but 
                                                        /// before starting to insert data

    string sqlPostFile;                                 /// name of the SQL statement file to run after inserting data



auto possibleValues = [ EnumMembers!OutputFormat ];

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
                // get command line arguments
                auto cmd = getopt(argv,
                    std.getopt.config.caseSensitive,
                    std.getopt.config.required     ,
                    "i"                            , &inputFileName          ,
                    std.getopt.config.required     ,
                    "l"                            , &inputLayout            ,
                    "o"                            , &outputFormat           ,
                    "O"                            , &stdOutput              ,
                    "of"                           , &givenOutputFileName    ,
                    "f"                            , &fieldFilterFile        ,
                    "ff"                           , &fieldFilter            ,
                    "fl"                           , &lineFilter             ,
                    "check"                        , &bCheckPattern          ,
                    "r"                            , &recordFilterFile       ,
                    "fr"                           , &recordFilter           ,
                    "v"                            , &bVerbose               ,
                    "s"                            , &samples                ,
                    "b"                            , &bJustRead              ,
                    "p"                            , &bProgressBar           ,
                    "c"                            , &bCheckLayout           ,
                    "br"                           , &bBreakRecord           ,
                    "dup"                          , &bPrintDuplicatedPattern,
                    "append"                       , &bAppendMode            , // not yet implemented
                    "ua"                           , &bUseAlternateNames     ,
                    "presql"                       , &sqlPreFile             ,
                    "postsql"                      , &sqlPostFile            ,
                    "stats"                        , &bDetailedStats         ,
                    "conf"                         , &cmdlineConfigFile
                );
            }
            catch (ConvException e) 
            {
                stderr.writefln(MSG043, possibleValues);
                core.stdc.stdlib.exit(2);
            }
            catch (Exception e) 
            {
                _printHelp(e.msg);
            }
        }

        // break record option is not compatible with some output formats
        if (bBreakRecord)
        {
            if (outputFormat != OutputFormat.txt && outputFormat != OutputFormat.box)
            {
                stderr.writefln(MSG044);
                core.stdc.stdlib.exit(3);
            }
        }

		// if a filter file is selected, use it. Same for field filter entered in the command line
		// append the suffix
		if (fieldFilterFile != "") 
        {
			enforce(exists(fieldFilterFile), MSG041.format(fieldFilterFile));
			filteredFields = cast(string)std.file.read(fieldFilterFile);
		} else if (fieldFilter != "") 
        {
			filteredFields = fieldFilter;
		}

		// if record file is specified, load conditions
		if (recordFilterFile != "") 
        {
			enforce(exists(recordFilterFile), MSG042.format(recordFilterFile));
			filteredRecords = new RecordFilter(cast(string)std.file.read(recordFilterFile), std.ascii.newline);
		} 
        else if (recordFilter != "") 
        {
			filteredRecords = new RecordFilter(recordFilter, ";");
		}

	}

	@property bool isFieldFilterFileSet()  { return fieldFilterFile != ""; }
	@property bool isFieldFilterSet()      { return fieldFilter != ""; }
	@property bool isRecordFilterFileSet() { return recordFilterFile != ""; }
	@property bool isRecordFilterSet()     { return recordFilter != ""; }

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
