// D import file generated from 'source\rbf\reader.d'
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
import rbf.field;
import rbf.record;
import rbf.layout;
alias STRING_MAPPER = void function(Record);
class Reader
{
	private 
	{
		immutable string _rbFile;
		Layout _layout;
		MapperFunc _recordIdentifier;
		Regex!char _ignoreRegex;
		STRING_MAPPER _mapper;
		ulong _currentReadSize;
		ulong _inputFileSize;
		public 
		{
			this(string rbFile, Layout layout, MapperFunc recIndentifier = null);
			@property void ignoreRegexPattern(Regex!char pattern);
			@property void recordTransformer(STRING_MAPPER func);
			@property Layout layout();
			@property ulong currentReadSize();
			@property ulong inputFileSize();
			Record _getRecordFromLine(char[] lineReadFromFile);
			struct Range
			{
				private 
				{
					File _fh;
					ulong _nbChars = (ulong).max;
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
