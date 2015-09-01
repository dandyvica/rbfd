import std.stdio;
import std.file;
import std.string;
import std.getopt;

import rbf.field;
import rbf.record;
import rbf.format;
import rbf.reader;
import rbf.writer;
import rbf.util;

import overpunch;


void main(string[] argv)
{
	string[] conditions;

	// read JSON properties
	auto config = new Config();

	// print-out help
	if (argv.length == 1)
	{
		writeln("
This program is aimed at reading record based file.
It reads its settings from the rbf.json file located in the ~/.rbf directory
(linux) or the %APPDATA%/local/rbf directory (Windows).

Usage: readrbf -i <input file name> -O <output file> -o <output format> -f <input format> -c <cond file>

	-i		file name and path of the file to read
	-o		output file name to generate
	-f		format of the input file (ex.: isr)
	-F		format of the output file. Should be only: html, csv, txt, xlsx or sqlite3
	-c		optional: a set of conditions for filtering records
		");
		core.stdc.stdlib.exit(1);
	}

	// get command line arguments
	CommandLineOption opts;
	getopt(argv,
		std.getopt.config.caseSensitive,
		"i",  &opts.inputFileName,
		"o",  &opts.outputFileName,
		"f", &opts.inputFormat,
		"F", &opts.outputFormat,
		"c",  &opts.conditionFile
	);

  // if no output file name specified, then use input file name and
	// append the suffix
	if (opts.outputFileName == "") {
		opts.outputFileName = opts.inputFileName ~ "." ~ opts.outputFormat;
	}

  // create new reader
	auto reader = reader(opts.inputFileName, config[opts.inputFormat]);

	// create new writer
	auto writer = writer(opts.outputFileName, opts.outputFormat);

	// in case of HOT files, specifiy our modifier
	reader.register_mapper = &overpunch.overpunch;

	/*
	if (opts.conditionFile != "")
	{
		conditions = reader.readCondition(opts.conditionFile);
		writeln(conditions);
	}
	*/

	foreach (rec; reader)
	{
		/*
		// store record depending on options
		if (opts.conditionFile != "" && rec.matchCondition(conditions))
		{
			writer.print(rec);
		}
		else
		{
			writer.print(rec);
		}*/
		writer.write(rec.fromList(["TDNR", "CDGT"]));
	}

	// explicitly call close to finish creating file (specially for Excel files)
	writer.close();

}
