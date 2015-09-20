// D import file generated from 'source/rbf/config.d'
module rbf.config;
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
import std.functional;
import std.regex;
import yaml;
alias RECORD_MAPPER = string delegate(string);
immutable yamlSettings = "rbf.yaml";
struct LayoutConfig
{
	string description;
	string mapping;
	string xmlFile;
	Regex!char ignoreRecord;
	string skipField;
	string layoutType;
	RECORD_MAPPER mapper;
}
class Setting
{
	private 
	{
		Node _document;
		string _zipper;
		string _rbfhome;
		public 
		{
			this();
			@property string zipper();
			LayoutConfig opIndex(string layoutName);
		}
	}
}
