import std.stdio;
import std.file;
import std.string;

import rbf.field;
import rbf.record;
import rbf.format;
import rbf.reader;
import rbf.writer;


void main(string[] argv)
{
	string[] conditions;

	// get command line arguments
	getopt(args, 
		"input|i",  &opts.inputFileName, 
		"output|o", &opts.outputFileName,
		"mode|m",   &opts.outputMode,
		"format|f", &opts.inputFormat,
		"clause|c", &opts.conditionFile
	);

	//writeln(opts);
	if (argv.length == 1)
	{
		writeln("
This program is aimed at reading record based file format.

Usage: rbf.exe -i <input file name> -o <output file> -m <mode> -f <format> -c <cond file>

	-i		file name and path and the file to read
	-o		file name to generate
	-m		format of the output file. Should be only html, csv, txt, xlsx or sql
	-f		format of the input file (ex.: isr)
	-c		optional: a set of conditions for filtering records
		");
		std.c.stdlib.exit(1);
	}

	// read properties from JSON file and depending on input file format,
	// fill structure
		
	auto reader = ReaderFactory(opts.inputFormat, opts.inputFileName);
	auto writer = writerFactory(opts.outputMode, opts.outputFileName);
	
	/*
	if (opts.conditionFile != "")
	{	
		conditions = reader.readCondition(opts.conditionFile);
		writeln(conditions);
	}
	*/
	
	foreach (rec; reader) 
	{
		// overpunch for HOT files but only for numerical fields
		if (opts.inputFormat == InputFormat.hot203)
		{
			foreach (Field f; rec) 
			{ 
					if (f.fieldType == FieldType.NUMERICAL) f.transmute(&overpunch); 
			}
		}
		
		// store record depending on options
		if (opts.conditionFile != "" && rec.matchCondition(conditions))
		{
			writer.print(rec);
		}
		else
		{
			writer.print(rec);
		}
	}
	
	// explicitly call destructor to finish creating file (specially for Excel files)
	delete writer;
	
}
