// D import file generated from 'source/conf.d'
module rbf.conf;
import std.stdio;
import std.file;
import std.string;
import std.process;
import std.json;
import std.conv;
import std.path;
import std.typecons;
import std.algorithm;
import std.range;
static Config configSettings;
enum mapperType 
{
	STRING_MAPPER,
	VARIABLE_MAPPER,
}
alias MAPPER = string delegate(string);
class RBFConfig
{
	private 
	{
		string _structureName;
		string _xmlStructure;
		alias Slice = Tuple!(int, int);
		mapperType _mappingType;
		string _constantMapping;
		Slice[] _sliceMapping;
		string _ignorePattern;
		MAPPER _record_mapper;
		char[] _recordName;
		public 
		{
			this(in string name, JSONValue tag);
			@property string xmlStructure();
			@property string ignorePattern();
			string record_identifier(string x);
			override string toString();
			private 
			{
				string _string_mapper(string x);
				string _variable_mapper(string x);
			}
		}
	}
}
class Config
{
	private 
	{
		JSONValue[string] document;
		RBFConfig[string] conf;
		string _zipper;
		public 
		{
			this();
			RBFConfig opIndex(string rbfFormat);
			@property string zipper();
		}
	}
}
