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
		Regex!char _lineRegex;
		STRING_MAPPER _mapper;
		ulong _nbLinesRead;
		ulong _inputFileSize;
		ulong _guessedRecordNumber;
		public 
		{
			this(string rbFile, Layout layout, MapperFunc recIndentifier = null)
			{
				enforce(exists(rbFile), "error: file %s not found".format(rbFile));
				_rbFile = rbFile;
				_layout = layout;
				_recordIdentifier = recIndentifier ? recIndentifier : layout.meta.mapper;
				_inputFileSize = getSize(rbFile);
				if (layout.meta.length != 0)
					_guessedRecordNumber = _inputFileSize / layout.meta.length;
				if (layout.meta.ignoreLinePattern != "")
					_ignoreRegex = regex(layout.meta.ignoreLinePattern);
			}
			@property void ignoreRegexPattern(string pattern)
			{
				_ignoreRegex = regex(pattern);
			}
			@property void lineRegexPattern(string pattern)
			{
				_lineRegex = regex(pattern);
			}
			@property ulong nbRecords()
			{
				return _guessedRecordNumber;
			}
			@property void recordTransformer(STRING_MAPPER func)
			{
				_mapper = func;
			}
			@property Layout layout()
			{
				return _layout;
			}
			@property ulong nbLinesRead()
			{
				return _nbLinesRead;
			}
			@property ulong inputFileSize()
			{
				return _inputFileSize;
			}
			Record _getRecordFromLine(char[] lineReadFromFile)
			{
				auto line = lineReadFromFile.idup;
				if (layout.meta.ignoreLinePattern != "" && matchFirst(line, _ignoreRegex))
				{
					return null;
				}
				if (!_lineRegex.empty && !matchFirst(line, _lineRegex))
				{
					return null;
				}
				auto recordName = _recordIdentifier(line);
				if (!(recordName in _layout))
				{
					writefln("error: record name <%s> not found!!", recordName);
					return null;
				}
				if (_layout[recordName].meta.skip)
					return null;
				_layout[recordName].value = line;
				if (_mapper)
					_mapper(_layout[recordName]);
				return _layout[recordName];
			}
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
						this(string fileName, Reader outer)
						{
							_fh = File(fileName);
							_outerThis = outer;
							do
							{
								_nbChars = _fh.readln(_buffer);
								if (_nbChars == 0)
									return ;
								_outerThis._nbLinesRead++;
								rec = _outerThis._getRecordFromLine(_buffer);
							}
							while (rec is null);
						}
						@property bool empty()
						{
							return _nbChars == 0;
						}
						@property ref Record front()
						{
							return rec;
						}
						void popFront()
						{
							do
							{
								_nbChars = _fh.readln(_buffer);
								if (_nbChars == 0)
									return ;
								_outerThis._nbLinesRead++;
								_buffer = _buffer.stripRight('\x0a');
								rec = _outerThis._getRecordFromLine(_buffer);
							}
							while (rec is null);
						}
					}
				}
			}
			Range opSlice()
			{
				return Range(_rbFile, this);
			}
		}
	}
}
