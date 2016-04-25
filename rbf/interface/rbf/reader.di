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
import rbf.stat;
class Reader
{
	private 
	{
		immutable string _rbFile;
		Layout _layout;
		MapperFunc _recordIdentifier;
		Regex!char _ignoreRegex;
		Regex!char _lineRegex;
		ulong _inputFileSize;
		Counter _guessedRecordNumber;
		bool _checkPattern;
		ulong _nbBadCheck;
		string _sectionName;
		public 
		{
			this(string rbFile, Layout layout, MapperFunc recIndentifier = null)
			{
				enforce(exists(rbFile), MSG051.format(rbFile));
				_rbFile = rbFile;
				_layout = layout;
				_recordIdentifier = recIndentifier ? recIndentifier : layout.meta.mapper;
				_inputFileSize = getSize(rbFile);
				if (layout.meta.length != 0)
					_guessedRecordNumber = _inputFileSize / (layout.meta.length + 1);
				if (layout.meta.ignoreLinePattern != "")
					_ignoreRegex = regex(layout.meta.ignoreLinePattern);
			}
			@property void ignoreRegexPattern(in string pattern)
			{
				_ignoreRegex = regex(pattern);
			}
			@property void lineRegexPattern(in string pattern)
			{
				_lineRegex = regex(pattern);
			}
			@property Counter nbGuessedRecords()
			{
				return _guessedRecordNumber;
			}
			@property Layout layout()
			{
				return _layout;
			}
			@property ulong inputFileSize()
			{
				return _inputFileSize;
			}
			@property ulong nbBadCheck()
			{
				return _nbBadCheck;
			}
			@property void checkPattern(in bool check)
			{
				_checkPattern = check;
			}
			Record _getRecordFromLine(in char[] lineReadFromFile)
			{
				Record rec;
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
				stat.nbRecs[recordName]++;
				if (!(recordName in _layout))
				{
					recordName = _layout.buildFieldNameWhenRoot(recordName, _sectionName);
					if (!(recordName in _layout))
					{
						log.warning(MSG018, stat.nbReadLines, recordName, 50, line[0..50]);
						return null;
					}
				}
				rec = _layout[recordName];
				if (rec.meta.section)
					_sectionName = recordName;
				else
					_sectionName = "";
				if (rec.meta.skipRecord)
					return null;
				rec.meta.sourceLineNumber = stat.nbReadLines;
				rec.value = line;
				if (_checkPattern)
				{
					foreach (f; rec)
					{
						if (f.value != "" && !f.matchPattern)
						{
							log.log(LogLevel.WARNING, MSG002, stat.nbReadLines, recordName, f.contextualInfo, f.value, f.pattern);
							_nbBadCheck++;
						}
					}
				}
				return rec;
			}
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
						this(string fileName, Reader outer)
						{
							_fh = File(fileName);
							_outerThis = outer;
							do
							{
								_nbChars = _fh.readln(_buffer);
								if (_nbChars == 0)
									return ;
								stat.nbReadLines++;
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
								stat.nbReadLines++;
								_buffer = _buffer.chomp;
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
