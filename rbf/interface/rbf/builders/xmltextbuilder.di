// D import file generated from 'source/rbf/builders/xmltextbuilder.d'
module rbf.builders.xmltextbuilder;
pragma (msg, "========> Compiling module ", "rbf.builders.xmltextbuilder");
import std.stdio;
import std.file;
import std.string;
import std.xml;
import std.conv;
import std.exception;
import std.algorithm;
import std.regex;
import std.array;
import std.path;
import rbf.errormsg;
import rbf.log;
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.builders.xmlcore;
import rbf.builders.xmlbuilder;
class RbfTextBuilder : RbfBuilder
{
	File _fh;
	string inputFile;
	string meta;
	string orphanMode;
	Sanitizer[string][string] sanitizer;
	this(string xmlFile)
	{
		enforce(exists(xmlFile), MSG088.format(xmlFile));
		string xmlData = cast(string)std.file.read(xmlFile);
		auto xml = new DocumentParser(xmlData);
		xml.onStartTag["meta"] = (ElementParser xml)
		{
			meta = xml.tag.toString;
		}
		;
		xml.onStartTag["input"] = (ElementParser xml)
		{
			inputFile = xml.tag.attr.get("file", "");
		}
		;
		xml.onStartTag["recordregex"] = (ElementParser xml)
		{
			this.recordRegex = xml.tag.attr.get("expr", "");
		}
		;
		xml.onStartTag["fieldregex"] = (ElementParser xml)
		{
			this.fieldRegex = xml.tag.attr.get("expr", "");
		}
		;
		xml.onStartTag["orphan"] = (ElementParser xml)
		{
			orphanMode = xml.tag.attr.get("mode", "");
		}
		;
		xml.onStartTag["attribute"] = (ElementParser xml)
		{
			auto tag = xml.tag.attr["tag"];
			auto attr = xml.tag.attr["name"];
			Sanitizer s;
			foreach (option; xml.tag.attr["options"].split(",").map!((e) => e.strip))
			{
				string regexes;
				auto indexOfEqual = option.indexOf('=');
				if (indexOfEqual != -1)
				{
					regexes = option[indexOfEqual + 1..$];
					option = option[0..indexOfEqual];
				}
				switch (option)
				{
					case "strip":
					{
						s.strip = true;
						break;
					}
					case "capitalize":
					{
						s.capitalize = true;
						break;
					}
					case "uppercase":
					{
						s.uppercase = true;
						break;
					}
					case "replace":
					{
						foreach (t; regexes.split(";"))
						{
							auto rep = t.split(":");
							s.replaceRegex ~= rep;
						}
						break;
					}
					default:
					{
						log.error(MSG056, option, tag, attr);
						break;
					}
				}
			}
			sanitizer[tag][attr] = s;
		}
		;
		xml.parse();
	}
	void processInputFile()
	{
		string[string] data;
		Record[] recList;
		FieldType[string] ftype;
		enforce(exists(inputFile), MSG089.format(inputFile));
		foreach (string line; lines(File(inputFile, "r")))
		{
			line = line.strip;
			if (line == "")
				continue;
			data = this.isRecordMatched(line);
			if (data != null)
			{
				_sanitizeData(data, "record");
				recList ~= new Record(data);
				continue;
			}
			data = this.isFieldMatched(line);
			if (data != null)
			{
				_sanitizeData(data, "field");
				recList[$ - 1] ~= new Field(data);
				auto type = data["type"];
				if (!(type in ftype))
				{
					switch (type)
					{
						case "AN":
						{
						}
						case "A/N":
						{
						}
						case "CHAR":
						{
							ftype[type] = new FieldType(type, "string");
							break;
						}
						case "I":
						{
							ftype[type] = new FieldType(type, "integer");
							break;
						}
						case "N":
						{
						}
						case "NUM":
						{
						}
						case "NUMC":
						{
							ftype[type] = new FieldType(type, "decimal");
							break;
						}
						default:
						{
							ftype[type] = new FieldType(type, "string");
							break;
						}
					}
				}
				continue;
			}
			if (orphanMode == "post" && recList.length != 0)
			{
				Field lastField = recList[$ - 1][].back;
				lastField.description = lastField.description ~ " " ~ line.strip;
			}
		}
		writeln("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\x0a<rbfile\x0a    xmlns=\"http://www.w3schools.com\"\x0a    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\x0a    xsi:schemaLocation=\"http://www.w3schools.com rbf.xsd\"\x0a>\x0a");
		writeln(meta);
		writeln;
		ftype.each!((ft) => writeln(ft.asXML));
		writeln;
		recList.each!((r) => writefln("%s\x0a", r.asXML));
		writeln("</rbfile>");
	}
	private void _sanitizeData(string[string] data, string tag)
	{
		if (tag in sanitizer)
		{
			foreach (attr; data.byKey)
			{
				if (attr in sanitizer[tag])
				{
					data[attr] = sanitizer[tag][attr].sanitize(data[attr]);
				}
			}
		}
	}
}
