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
import rbf.log;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.stat;

// definition of useful aliases
//alias STRING_MAPPER = void function(Record);           /// alias to a delegate used to change field values

/***********************************
 * record-base file reader used to loop on each record
 */
class Reader 
{

private:

	immutable string _rbFile;               /// filename to read
	Layout _layout;                         /// list of all records read from XML definition file
	MapperFunc _recordIdentifier;           /// this function will identify a record name from the line read
	Regex!char _ignoreRegex;                /// regex ignore pattern: don't read those lines matching this regex
	                                        /// regex include pattern: read only those lines matching this regex
	Regex!char _lineRegex;                  /// but previous one comes first
	//STRING_MAPPER _mapper;                  /// mapper function which can be defined to transform a record
	ulong _nbLinesRead;                     /// size read
	ulong _inputFileSize;                   /// input file size
    ulong _guessedRecordNumber;             /// guessed number of records (in case of a lauyout having reclength!=0)
    bool _checkPattern;                     /// do we want to check field pattern for each record?
    ulong _nbBadCheck;                      /// counter for those bad formatted fields

    string _sectionName;                     /// last fetched record name

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
		// record-based file must exist
		enforce(exists(rbFile), MSG051.format(rbFile));

		// save file name and opens file for reading
		_rbFile = rbFile;

		// save layout container object
		_layout = layout;

		// save record hash identifier lambda
		_recordIdentifier = (recIndentifier) ? recIndentifier : layout.meta.mapper;

		// get file size and try to calculate number of records
        // this is used to print out progression of reading. But it is only meaningful when
        // each line of the input file has the same length
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
	@property void ignoreRegexPattern(in string pattern) { _ignoreRegex = regex(pattern); }
	@property void lineRegexPattern(in string pattern)   { _lineRegex   = regex(pattern); }

	@property ulong nbRecords()   { return _guessedRecordNumber; }

	/**
	 * register a callback function which will be called for each fetched record
	 */
	//@property void recordTransformer(STRING_MAPPER func) { _mapper = func; }

	@property Layout layout() { return _layout; }

	@property ulong nbLinesRead() { return _nbLinesRead; }

	/// return the file size of the input file in bytes
	@property ulong inputFileSize() { return _inputFileSize; }

	@property ulong nbBadCheck() { return _nbBadCheck; }

	@property void checkPattern(in bool check) { _checkPattern = check; }

	Record _getRecordFromLine(in char[] lineReadFromFile) 
    {
        // current record found
        Record rec;

		// convert to string
		auto line = lineReadFromFile.idup;

		// if line is matching the ignore pattern, just loop to ignore this line
		if (layout.meta.ignoreLinePattern != "" && matchFirst(line, _ignoreRegex)) 
        {
			return null;
		}

		// if line is not matching the line pattern, just loop
		if (!_lineRegex.empty && !matchFirst(line, _lineRegex)) 
        {
			return null;
		}

		// try to fetch the corresponding record name for line we've read
        // using the hash matching method
		auto recordName = _recordIdentifier(line);

		// record not found ? So loop
        if (recordName !in _layout) 
        {
            recordName = _layout.buildFieldNameWhenRoot(recordName, _sectionName);
            if (recordName !in _layout)
            {
                log.log(LogLevel.WARNING, MSG018, _nbLinesRead, recordName);
                return null;
            }
        }

        // save our record because our hash function has sent back something
        rec = _layout[recordName];

        // if this record starts a new section, keep its name
        if (rec.meta.section) 
            _sectionName = recordName;
        else
            _sectionName = "";

		// do we keep this record? sometimes, we skip records when setting record or field filters
		if (rec.meta.skipRecord) return null;

        // keep track of the original line number: useful for pointing out errors in the rb-file
        rec.meta.sourceLineNumber = _nbLinesRead;

		// now we can safely save our values
		// set record value (and fields)
		rec.value = line;

		// is a mapper registered? so we need to call it
		//if (_mapper) _mapper(rec);

        // do we need to check field patterns?
        if (_checkPattern)
        {
            // so for each field, we verify if field value is matching the field pattern
            foreach (f; rec)
            {
                if (f.value != "" && !f.matchPattern) 
                {
                    log.log(LogLevel.WARNING, MSG002, _nbLinesRead, recordName, f.contextualInfo, f.value, f.pattern);
                    _nbBadCheck++;
                }
            }
		}

		// return to caller our record
		return rec;

	}

    // inner structure for defining a range for our container
    struct Range 
    {
        private:
            File _fh;                       /// file handle on opened file
            size_t _nbChars = size_t.max;   /// number of chars reads for each line
            char[] _buffer;                 /// buffer read from filee
            Reader _outerThis;              /// pointer on enclosing this
            Record rec;                     /// read record object

        public:
            // this constructor will be called from helper function []
            // need to get access to the outer class this
            this(string fileName, Reader outer) 
            {
                // open file in read only mode
                _fh = File(fileName);
                //_fh.setvbuf(65536);

                // save enclosing this
                _outerThis = outer;

                // read each line until we find a record
                do 
                {
                    // read one line from file
                    _nbChars = _fh.readln(_buffer);

                    // no char read? This means we've reached the end of file
                    if (_nbChars == 0) return;

                    // now, we've read one additional line from file
                    _outerThis._nbLinesRead++;
                    //stat.nbPhysicalLines++;

                    // identify record from line
                    rec = _outerThis._getRecordFromLine(_buffer);

                } while (rec is null);

            }

            // because file pointer moves ahead, all logic is in this method
            @property bool empty() { return _nbChars == 0; }
            @property ref Record front() { return rec; }
            // does nothing because file pointer already move on
            void popFront() 
            {

                // more or less tje same logic than from the ctor
                do 
                {
                    // read one line from file
                    _nbChars = _fh.readln(_buffer);

                    // if eof, just return
                    if (_nbChars == 0) return;

                    _outerThis._nbLinesRead++;

                    // get rid of EOL
                    //_buffer = _buffer.stripRight('\n');
                    _buffer = _buffer.chomp;

                    // try to get a record from that line
                    // call outer class this
                    rec = _outerThis._getRecordFromLine(_buffer);

                } while (rec is null);

            }

    }

	/// Return a range on the container. This is a helper function mimiced on
    /// container Dlang libs
	Range opSlice() 
    {
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
