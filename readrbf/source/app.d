import std.stdio;
import std.file;
import std.string;
import std.getopt;

import rbf.field;
import rbf.record;
import rbf.format;
import rbf.reader;
import rbf.writer;
import rbf.conf;
import rbf.args;

import overpunch;


void main(string[] argv)
{
	string[] conditions;

	// read JSON properties
	auto config = new Config();

	// manage arguments
	auto opts = new CommandLineOption(argv);

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
		if (rec.matchCondition(["TDNR ~ ^05754"]))
		{
			writeln(rec);
			continue;
		}
		//writeln(rec.get("TDNR").matchCondition("~", "^05754"));


		// ask for a restriction?
		if (opts.isRestriction) {
			// only print out rec if record name is found is the restriction file
			if (rec.name in opts.fieldNames) {
				auto fieldNamesToKeep = opts.fieldNames[rec.name];
				writer.write(rec.fromList(fieldNamesToKeep));
			}
		}
		else
			writer.write(rec);
	}

	// explicitly call close to finish creating file (specially for Excel files)
	writer.close();

}
