// D import file generated from 'source/rbf/reader.d'
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
alias GET_RECORD_FUNCTION = string delegate(string);
alias STRING_MAPPER = void function(Record);
class Reader
{
	private 
	{
		immutable string _rbFile;
		Layout _layout;
		GET_RECORD_FUNCTION _recordIdentifier;
		Regex!char _ignoreRegex;
		STRING_MAPPER _mapper;
		ulong _currentReadSize;
		ulong _inputFileSize;
		public 
		{
			this(string rbFile, Layout layout, GET_RECORD_FUNCTION recIndentifier);
			@property void ignoreRegexPattern(Regex!char pattern);
			@property void recordTransformer(STRING_MAPPER func);
			@property Layout layout();
			@property ulong currentReadSize();
			@property ulong inputFileSize();
			int opApply(int delegate(ref Record) dg);
		}
	}
}
