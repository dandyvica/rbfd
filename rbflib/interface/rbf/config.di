// D import file generated from 'source/config.d'
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
import yaml;
alias RECORD_MAPPER = string delegate(string);
struct LayoutConfig
{
	string description;
	string mapping;
	string xmlFile;
	string ignorePattern;
	string skipField;
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
