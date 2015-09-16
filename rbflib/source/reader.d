/**
 * Authors: Alain Viguier
 * Date: 03/04/2015
 * Version: 0.1
 */
module rbf.reader;

import std.stdio;
import std.file;
import std.string;
import std.conv;
import std.exception;
import std.regex;


import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.conf;

//import util.common;

// definition of useful aliases
alias GET_RECORD_FUNCTION = string delegate(string);   /// alias for a function pointer which identifies a record
alias STRING_MAPPER = void function(Record);           /// alias to a delegate used to change field values


/***********************************
 * record-base file reader used to loop on each record
 */
class Reader {

private:

	/// filename to read
	immutable string _rbFile;

	/// file handle when opened
	//File _fh;

	/// list of all records read from XML definition file
	Layout _layout;

	/// this function will identify a record name from the line read
	GET_RECORD_FUNCTION _recIdent;

	/// regex ignore pattern: don't read those lines matching this regex
	string _ignore_pattern;

	/// mapper function
	STRING_MAPPER _mapper;

public:
	/**
	 * creates a new Reader object for rb files
	 *
	 * Params:
	 *  rbFile = path/name of the file to read
	 *  xmlFile = xml file containing fields & records definitions
	 *  recIndentifier = function used to map each record
	 */
	this(string rbFile, Layout layout, GET_RECORD_FUNCTION recIndentifier)
	{
		// check arguments
		enforce(exists(rbFile), "File %s not found".format(rbFile));

		// save file name and opens file for reading
		_rbFile = rbFile;

		// open file for reading
		//_fh = File(rbFile, "r");

		// build all records but defining a new format
		_layout = layout;

		// save record identifier lambda
		_recIdent = recIndentifier;

	}

	/**
	 * register a regex pattern to ignore line matching this pattern
	 *
	 * Examples:
	 * -----------------------------
	 * reader.ignore_pattern("^#")		// ignore lines starting with #
	 * -----------------------------
	 */
	@property void ignore_pattern(string pattern) { _ignore_pattern = pattern; }

	/**
	 * register a callback function which will be called for each fetched record
	 */
	@property void register_mapper(STRING_MAPPER func) { _mapper = func; }

	@property Layout layout() { return _layout; }

	/**
	 * used to loop on foreach on all records of the file
	 *
	 * Examples:
	 * -----------------------------
	 * foreach (Record rec; rbfile)
	 * 	{ writeln(rec); }
	 * -----------------------------
	 */
	int opApply(int delegate(ref Record) dg)
	{
		int result = 0;
		string recordName;

		// read each line of the ascii file
		//foreach (string line_read; lines(File(_rbFile, "r")))
		foreach (string line_read; lines(File(_rbFile)))
		{
			// get rid of \n
			auto line = chomp(line_read);

			// if line is matching the ignore pattern, just loop
			if (_ignore_pattern != "" && matchFirst(line, regex(_ignore_pattern))) {
				continue;
			}

			// try to fetch corresponding record name for line we've read
			recordName = _recIdent(line);

			// record not found ? So loop
			if (recordName !in _layout.records) {
				writefln("record name <%s> not found!!", recordName);
				continue;
			}

			// do we keep this record?
			if (!_layout[recordName].keep) continue;

			// now we can safely save our values
			// set record value (and fields)
			_layout[recordName].value = line;

			// is a mapper registered? so we need to call it
			if (_mapper)
				_mapper(_layout[recordName]);

			// save line
			//_layout[recordName].line = line;

			// this is conventional way of opApply()
			result = dg(_layout[recordName]);
			if (result)
				break;
		}
		return result;
	}

	/**
	 * destructor: close the file
	~this() {
		_fh.close();
	}

	*/
	/**
	 * read the condition file and return an array of string, one string
	 * per condition
	 */
	/*
	string[] readCondition(string fileName)
	{
		string[] cond;

		enforce(exists(fileName), "Condition file %s not found".format(fileName));

		foreach (string line; File(fileName, "r").lines)
		{
			if (!startsWith(line, "#")) cond ~= line.stripRight();
		}

		return cond;
	} */


}

/*
Reader reader(string rbFile, RBFConfig rbfConfig)
{
	return new Reader(rbFile, rbfConfig.xmlStructure, &rbfConfig.record_identifier);
}
*/



unittest {

	writefln("-------------------------------------------------------------");
	writeln(__FILE__);
	writefln("-------------------------------------------------------------");

	void mapper(Record rec) {
		foreach (f; rec) { f.value = "TTT"; }
	}

	auto rbf = new Reader("../test/world.data", "../test/world_data.xml", (line => line[0..4] ));

	//auto conditions = rbf.readCondition("conds.txt");
	//writeln(conditions);

	rbf.ignore_pattern = "^#";
	//rbf.register_mapper = &mapper;

	foreach (rec; rbf) {
		//if (rec.matchCondition(conditions)) writeln(rec.toTxt);
		//writeln(rec.toTxt()());
		writeln(rec.toTxt());
	}


}
