// D import file generated from 'source/reader.d'
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
alias GET_RECORD_FUNCTION = string delegate(string);
alias STRING_MAPPER = void function(Record);
class Reader
{
	private 
	{
		immutable string _rbFile;
		Layout _layout;
		GET_RECORD_FUNCTION _recIdent;
		string _ignore_pattern;
		STRING_MAPPER _mapper;
		public 
		{
			this(string rbFile, Layout layout, GET_RECORD_FUNCTION recIndentifier);
			@property void ignore_pattern(string pattern);
			@property void register_mapper(STRING_MAPPER func);
			@property Layout layout();
			int opApply(int delegate(ref Record) dg);
		}
	}
}
