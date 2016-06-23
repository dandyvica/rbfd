module rbf.settings;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.process;
import std.xml;
import std.conv;
import std.path;
import std.typecons;
import std.algorithm;
import std.range;
import std.functional;
import std.regex;
import std.traits;
import std.exception;
import core.stdc.stdlib;

import rbf.errormsg;
import rbf.log;
import rbf.config;
import rbf.nameditems;
import rbf.layout;
import rbf.args;
import rbf.convert;
import rbf.writers.writer : OutputFormat;
import rbf.builders.xmltextbuilder;

/***********************************
	* class for reading XML definition file
 */
struct Settings 
{

    CommandLineOption cmdLineOptions;
    OutputConfiguration outputConfiguration;
    SettingCore layoutConfiguration;

    string outputFormat;
    string output;
    string outputFileName;

    void manage(string[] argv)
    {
        //---------------------------------------------------------------------------------
		// manage arguments passed from the command line
        //---------------------------------------------------------------------------------
		cmdLineOptions = CommandLineOption(argv);

        //---------------------------------------------------------------------------------
		// configuration file passed as argument? Use it if neccessary
        //---------------------------------------------------------------------------------
        ConfigFromXMLFile configFromXMLFile;
        if (cmdLineOptions.cmdLineArgs.cmdlineConfigFile != "")
        {
            configFromXMLFile = new ConfigFromXMLFile(cmdLineOptions.cmdLineArgs.cmdlineConfigFile);
        }
        else
        {
            // take the default configuration file
		    configFromXMLFile = new ConfigFromXMLFile();
        }

        // now, we are sure log is initialized

        //---------------------------------------------------------------------------------
		// some options need to be set up after XML configuration load
        //---------------------------------------------------------------------------------
        if (argv.length == 2 && argv[1] == "--layouts")
        {
            configFromXMLFile.listLayouts;
            exit(1);
        }

        //--------------------------------------------------------------------
        // readrbf --buildxml file.xml
        //--------------------------------------------------------------------
        with(cmdLineOptions.cmdLineArgs)
        {
            if (xmlConfigFile != "")
            {
                auto r = new RbfTextBuilder(xmlConfigFile);
                r.processInputFile;
                exit(2);
            }
        }

        //--------------------------------------------------------------------
        // readrbf --validate layout.xml
        //--------------------------------------------------------------------
        with(cmdLineOptions.cmdLineArgs)
        {
            if (layoutFile != "")
            {
                auto layout = new Layout(layoutFile);
                layout.validate;
                exit(2);
            }
        }

        //--------------------------------------------------------------------
        // readrbf --convert layout.xml --format csv
        //--------------------------------------------------------------------
        with(cmdLineOptions.cmdLineArgs)
        {
            if (layoutFileToConvert != "")
            {
                // check arguments
                if (convFormat == Format.temp && templateFile == "")
                {
                    Log.console(Message.MSG091);
                }
                else
                {
                    // call conversion function
                    convertLayout(layoutFileToConvert,  convFormat, templateFile);
                }
                exit(2);
            }
        }

        //---------------------------------------------------------------------------------
        // now build settings from command line args and XML configuration
		// output format is an enum but should match the string in rbf.xml config file
        //---------------------------------------------------------------------------------
        outputFormat = to!string(cmdLineOptions.cmdLineArgs.outputFormat);
		outputConfiguration = configFromXMLFile.outputList[outputFormat];
        layoutConfiguration = configFromXMLFile.layoutList[cmdLineOptions.cmdLineArgs.inputLayout];

        //---------------------------------------------------------------------------------
		// use output file name if given or build it
        //---------------------------------------------------------------------------------
        if (cmdLineOptions.cmdLineArgs.givenOutputFileName != "")
        {
            cmdLineOptions.outputFileName = cmdLineOptions.cmdLineArgs.givenOutputFileName;
        }
        else
        {
            cmdLineOptions.outputFileName = baseName(cmdLineOptions.cmdLineArgs.inputFileName) ~ "." ~ configFromXMLFile.outputList[outputFormat].outputFileExtension;
        }

        //---------------------------------------------------------------------------------
		// check if œoutput format is valid
        //---------------------------------------------------------------------------------
		if (outputFormat !in configFromXMLFile.outputList) 
        {
			throw new Exception(Message.MSG058.format(configFromXMLFile.outputList.names));
		}

        //---------------------------------------------------------------------------------
		// use alternate names if requested
        //---------------------------------------------------------------------------------
		if (cmdLineOptions.cmdLineArgs.bUseAlternateNames) 
        {
			outputConfiguration.useAlternateName = true;
		}

        //---------------------------------------------------------------------------------
		// save template file if any
        //---------------------------------------------------------------------------------
		if (cmdLineOptions.cmdLineArgs.templateFile != "") 
        {
			outputConfiguration.templateFile = cmdLineOptions.cmdLineArgs.templateFile;
		}

		outputFileName = buildNormalizedPath(
				configFromXMLFile.outputList[outputFormat].outputDirectory,
				cmdLineOptions.outputFileName
		);

		output = (cmdLineOptions.cmdLineArgs.stdOutput) ? "" : outputFileName;

        // SQL format adds additonal feature for SQL
        if  (cmdLineOptions.cmdLineArgs.outputFormat == OutputFormat.sqlite3
          || cmdLineOptions.cmdLineArgs.outputFormat == OutputFormat.postgres) 
        {
            outputConfiguration.sqlPreFile  = cmdLineOptions.cmdLineArgs.sqlPreFile;
            outputConfiguration.sqlPostFile = cmdLineOptions.cmdLineArgs.sqlPostFile;
        }

        // add additional parameters
        outputConfiguration.useRawValue = cmdLineOptions.cmdLineArgs.useRawValue;

    }

}
///
unittest {
	writeln("========> testing ", __FILE__);
}
