// D import file generated from 'source/rbf/reader.d'
module rbf.reader;
pragma (msg, "========> Compiling module ", "rbf.reader");
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
class Reader
{
	private 
	{
		immutable string _rbFile;
		Layout _layout;
		MapperFunc _recordIdentifier;
		Regex!char _ignoreRegex;
		Regex!char _lineRegex;
		ulong _nbLinesRead;
		ulong _inputFileSize;
		ulong _guessedRecordNumber;
		bool _checkPattern;
		ulong _nbBadCheck;
		string _sectionName;
		public 
		{
			this(string rbFile, Layout layout, MapperFunc recIndentifier = null);
			@property void ignoreRegexPattern(in string pattern);
			@property void lineRegexPattern(in string pattern);
			@property ulong nbRecords();
			@property Layout layout();
			@property ulong nbLinesRead();
			@property ulong inputFileSize();
			@property ulong nbBadCheck();
			@property void checkPattern(in bool check);
			Record _getRecordFromLine(in char[] lineReadFromFile);
			struct Range
			{
				private 
				{
					File _fh;
					size_t _nbChars = size_t.max;
					char[] _buffer;
					Reader _outerThis;
					Record rec;
					public 
					{
						this(string fileName, Reader outer);
						@property bool empty();
						@property ref Record front();
						void popFront();
					}
				}
			}
			Range opSlice();
		}
	}
}
