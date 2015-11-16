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

import rbf.errormsg;
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

	/// regex include pattern: read only those lines matching this regex
	/// but previous one comes first
	Regex!char _lineRegex;


	/// mapper function
	STRING_MAPPER _mapper;

	/// size read
	ulong _nbLinesRead;

    ulong _currentLineNumber;

	/// input file size
	ulong _inputFileSize;

    /// guessed number of records (in case of a lauyout having reclength!=0)
    ulong _guessedRecordNumber;

    bool _checkPattern;

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

		// build all records but defining a new format
		_layout = layout;

		// save record identifier lambda
		_recordIdentifier = (recIndentifier) ? recIndentifier : layout.meta.mapper;

		// get file size and try to calculate number of records
		_inputFileSize = getSize(rbFile);
        if (layout.meta.length != 0) _guessedRecordNumber = _inputFileSize / (layout.meta.length+1);

		// set regex if any
		if (layout.meta.ignoreLinePattern != "")
			_ignoreRegex = regex(layout.meta.ignoreLinePattern);
	}

	/**
	 * register a regex pattern to ignore line matching this pattern
	 *
	 * Examples:
	 * -----------------------------
	 * reader.ignoreRegexPattern("^#")		// ignore lines starting with #
	 * -----------------------------
	 */
	@property void ignoreRegexPattern(string pattern) { _ignoreRegex = regex(pattern); }
	@property void lineRegexPattern(string pattern)   { _lineRegex   = regex(pattern); }

	@property ulong nbRecords()   { return _guessedRecordNumber; }

	/**
	 * register a callback function which will be called for each fetched record
	 */
	@property void recordTransformer(STRING_MAPPER func) { _mapper = func; }

	@property Layout layout() { return _layout; }

	@property ulong nbLinesRead() { return _nbLinesRead; }

	/// return the file size of the input file in bytes
	@property ulong inputFileSize() { return _inputFileSize; }

	@property void checkPattern(bool check) { _checkPattern = check; }

	Record _getRecordFromLine(char[] lineReadFromFile) {

		// get rid of \n
		auto line = lineReadFromFile.idup;

		// if line is matching the ignore pattern, just loop
		if (layout.meta.ignoreLinePattern != "" && matchFirst(line, _ignoreRegex)) {
			return null;
		}

		// if line is not matching the line pattern, just loop
		if (!_lineRegex.empty && !matchFirst(line, _lineRegex)) {
			return null;
		}

		// try to fetch corresponding record name for line we've read
		auto recordName = _recordIdentifier(line);

		// record not found ? So loop
		if (recordName !in _layout) {
            log.log(LogLevel.WARNING, MSG018, _nbLinesRead, recordName);
			return null;
		}

		// do we keep this record?
		if (_layout[recordName].meta.skip) return null;

		// now we can safely save our values
		// set record value (and fields)
		_layout[recordName].value = line;

		// is a mapper registered? so we need to call it
		if (_mapper)
			_mapper(_layout[recordName]);

        // do we need to check field patterns?
        if (_checkPattern)
        {
            foreach (f;  _layout[recordName])
            {
                if (f.value != "" && !f.matchPattern) 
                {
                    log.log(LogLevel.WARNING, MSG002, _nbLinesRead, recordName, f.name, f.value, f.type.meta.pattern);
                }
            }
		}

		// return to caller our record
		return _layout[recordName];

	}

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

					_outerThis._nbLinesRead++;

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

					_outerThis._nbLinesRead++;

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

}
///
unittest {
	writeln("========> testing ", __FILE__);
	auto layout = new Layout("./test/world_data.xml");
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
