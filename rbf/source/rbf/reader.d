/**
 * Authors: Alain Viguier
 * Date: 03/04/2015
 * Version: 0.1
 */
module rbf.reader;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.conv;
import std.exception;
import std.regex;
import std.range;
import std.algorithm;

import rbf.field;
import rbf.record;
import rbf.layout;

// definition of useful aliases
//alias GET_RECORD_FUNCTION = string delegate(string);   /// alias for a function pointer which identifies a record
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
	MapperFunc _recordIdentifier;

	/// regex ignore pattern: don't read those lines matching this regex
	Regex!char _ignoreRegex;

	/// mapper function
	STRING_MAPPER _mapper;

	/// size read
	ulong _currentReadSize;

	/// input file size
	ulong _inputFileSize;

public:
	/**
	 * creates a new Reader object for rb files
	 *
	 * Params:
	 *  rbFile = path/name of the file to read
	 *  layout = layout object
	 *  recIndentifier = function used to map each record
	 */
	this(string rbFile, Layout layout, MapperFunc recIndentifier = null)
	{
		// check arguments
		enforce(exists(rbFile), "error: file %s not found".format(rbFile));

		// save file name and opens file for reading
		_rbFile = rbFile;

		// open file for reading
		//_fh = File(rbFile, "r");

		// build all records but defining a new format
		_layout = layout;

		// save record identifier lambda
		_recordIdentifier = (recIndentifier) ? recIndentifier : layout.meta.mapper;
		//_recordIdentifier = layout.meta.mapper;

		// get file size
		_inputFileSize = getSize(rbFile);
	}

	/**
	 * register a regex pattern to ignore line matching this pattern
	 *
	 * Examples:
	 * -----------------------------
	 * reader.ignoreRegexPattern("^#")		// ignore lines starting with #
	 * -----------------------------
	 */
	@property void ignoreRegexPattern(Regex!char pattern) { _ignoreRegex = pattern; }

	/**
	 * register a callback function which will be called for each fetched record
	 */
	@property void recordTransformer(STRING_MAPPER func) { _mapper = func; }

	@property Layout layout() { return _layout; }

	@property ulong currentReadSize() { return _currentReadSize; }

	/// return the file size of the input file in bytes
	@property ulong inputFileSize() { return _inputFileSize; }


	Record _getRecordFromLine(char[] lineReadFromFile) {

		// get rid of \n
		auto line = lineReadFromFile.idup;

		// if line is matching the ignore pattern, just loop
		if (!layout.meta.ignoreRecord.empty && matchFirst(line, layout.meta.ignoreRecord)) {
			return null;
		}

		// try to fetch corresponding record name for line we've read
		auto recordName = _recordIdentifier(line);

		// record not found ? So loop
		if (recordName !in _layout) {
			writefln("error: record name <%s> not found!!", recordName);
			return null;
		}

		// do we keep this record?
		if (!_layout[recordName].meta.keep) return null;

		// now we can safely save our values
		// set record value (and fields)
		_layout[recordName].value = line;

		// is a mapper registered? so we need to call it
		if (_mapper)
			_mapper(_layout[recordName]);

		// return to caller our record
		return _layout[recordName];

	}

/*
	// inner structure for defining a range for our container
	struct Range {
		private:
			File _fh;
			ulong _nbChars = ulong.max;
			char[] _buffer;
			Reader _outerThis;
			Record rec;

		public:
				// this constructor will be called from helper function []
				// need to get access to the outer class this
			this(string fileName, Reader outer) {
				_fh = File(fileName);
				_outerThis = outer;
			}

			// because file pointer moves ahead, all logic is in this method
			@property bool empty() {
				do {
					// read one line from file
					_nbChars = _fh.readln(_buffer);

					// if eof, just return
					if (_nbChars == 0) { return true; }

					// get rid of \n
					_buffer = _buffer.stripRight('\n');

					// try to get a record from that line
					// call outer class this
					rec = _outerThis._getRecordFromLine(_buffer);
				} while (rec is null);

				return false;
			}
			@property ref Record front() {
				//writefln("rec=%s", rec.name);
				return rec;
			}
			// does nothing because file pointer already move on
			void popFront() {	}

	}
	*/

	// inner structure for defining a range for our container
	struct Range {
		private:
			File _fh;
			ulong _nbChars = ulong.max;
			char[] _buffer;
			Reader _outerThis;
			Record rec;

		public:
				// this constructor will be called from helper function []
				// need to get access to the outer class this
			this(string fileName, Reader outer) {
				_fh = File(fileName);
				_outerThis = outer;

				do {
					_nbChars = _fh.readln(_buffer);
					if (_nbChars == 0) return;
					rec = _outerThis._getRecordFromLine(_buffer);
				} while (rec is null);

			}

			// because file pointer moves ahead, all logic is in this method
			@property bool empty() { return _nbChars == 0; }
			@property ref Record front() {
				//writefln("rec=%s", rec.name);
				return rec;
			}
			// does nothing because file pointer already move on
			void popFront() {

				do {
					// read one line from file
					_nbChars = _fh.readln(_buffer);

					// if eof, just return
					if (_nbChars == 0) return;

					// get rid of \n
					_buffer = _buffer.stripRight('\n');

					// try to get a record from that line
					// call outer class this
					rec = _outerThis._getRecordFromLine(_buffer);
				} while (rec is null);


			}

	}

	/// Return a range on the container
	Range opSlice() {
		return Range(_rbFile, this);
	}


	/**
	 * used to loop on foreach on all records of the file
	 *
	 * Examples:
	 * -----------------------------
	 * foreach (Record rec; rbfile)
	 * 	{ writeln(rec); }
	 * -----------------------------
	 */
	/*
	int opApply(int delegate(ref Record) dg)
	{
		int result = 0;
		string recordName;

		// read each line of the ascii file
		//foreach (string line_read; lines(File(_rbFile, "r")))
		foreach (string line_read; lines(File(_rbFile)))
		{
			// one more line read
			_currentReadSize += line_read.length;

			// get rid of \n
			auto line = chomp(line_read);

			// if line is matching the ignore pattern, just loop
			if (!_ignoreRegex.empty && matchFirst(line, _ignoreRegex)) {
				continue;
			}

			// try to fetch corresponding record name for line we've read
			recordName = _recordIdentifier(line);

			// record not found ? So loop
			if (recordName !in _layout) {
				writefln("error: record name <%s> not found!!", recordName);
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

			// this is conventional way of opApply()
			result = dg(_layout[recordName]);
			if (result)
				break;
		}
		return result;
	}*/

}
///
unittest {
	writeln("========> testing ", __FILE__);
	auto layout = new Layout("./test/world_data.xml");
	//auto reader = new Reader("./test/world.data", layout, (line => line[0..4]));
	auto reader = new Reader("./test/world.data", layout);

	//reader[].filter!(e => e.name == "CONT").each!(e => writeln(e["NAME"][0].value));
	auto list = array(reader[].filter!(e => e.name == "CONT").map!(e => e["NAME"][0].value));
	assert(list == ["Asia", "Africa", "North America", "South America", "Antarctica", "Europe", "Oceania"]);
	//foreach (r; reader) { writeln(r.name, " ", r.NAME); }

	// foreach is as always
	/*
	foreach (rec; reader) {
		assert("NAME" in rec);
	}*/
}
