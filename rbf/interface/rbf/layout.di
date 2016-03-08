// D import file generated from 'source/rbf/layout.d'
module rbf.layout;
pragma (msg, "========> Compiling module ", "rbf.layout");
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
import rbf.options;
import rbf.nameditems;
import rbf.stat;
version (unittest)
{
	immutable test_file = "./test/world_data.xml";
}
alias MapperFunc = string delegate(TVALUE);
template LayoutCore()
{
	string name;
	string description;
	string file;
}
struct LayoutMeta
{
	mixin LayoutCore!();
	ulong length;
	string layoutVersion;
	string ignoreLinePattern;
	string[] skipField;
	MapperFunc mapper;
	string mapperDefinition;
}
class Layout : NamedItemsContainer!(Record, false, LayoutMeta)
{
	private 
	{
		void _extractMapper(string mapper)
		{
			auto r1 = regex("(\\d+)\\.\\.(\\d+)");
			auto r2 = regex("(\\d+)\\.\\.(\\d+)\\s*,\\s*(\\d+)\\.\\.(\\d+)");
			auto mapperReg = regex("^type:(\\d)\\s+map:\\s*([\\w\\.,]+)\\s*$");
			auto m = matchAll(mapper, mapperReg);
			auto funcType = to!byte(m.captures[1]);
			switch (funcType)
			{
				case 0:
				{
					meta.mapper = (TVALUE x) => m.captures[2];
					break;
				}
				case 1:
				{
					auto m1 = matchAll(m.captures[2], r1);
					meta.mapper = (TVALUE x) => x[to!size_t(m1.captures[1])..to!size_t(m1.captures[2])];
					break;
				}
				case 2:
				{
					auto m2 = matchAll(m.captures[2], r2);
					meta.mapper = (TVALUE x) => x[to!size_t(m2.captures[1])..to!size_t(m2.captures[2])] ~ x[to!size_t(m2.captures[3])..to!size_t(m2.captures[4])];
					break;
				}
				default:
				{
					throw new Exception(MSG036.format(funcType, meta.file));
				}
			}
		}
		public 
		{
			FieldType[string] ftype;
			this(string xmlFile)
			{
				enforce(exists(xmlFile), MSG037.format(xmlFile));
				meta.file = xmlFile;
				meta.name = baseName(xmlFile);
				string xmlData = cast(string)std.file.read(xmlFile);
				super(baseName(xmlFile));
				string recName;
				auto xml = new DocumentParser(xmlData);
				xml.onStartTag["meta"] = (ElementParser xml)
				{
					auto recLength = xml.tag.attr.get("reclength", "0");
					meta.length = recLength != "" ? to!ulong(recLength) : 0;
					meta.layoutVersion = xml.tag.attr.get("version", "");
					meta.ignoreLinePattern = xml.tag.attr.get("ignoreLine", "");
					meta.description = xml.tag.attr.get("description", "");
					auto fields = xml.tag.attr.get("skipField", "");
					if (fields != "")
					{
						meta.skipField = array(fields.split(',').map!((e) => e.strip));
					}
					if (!("mapper" in xml.tag.attr) || xml.tag.attr["mapper"] == "")
					{
						throw new Exception(MSG038);
					}
					_extractMapper(xml.tag.attr["mapper"]);
					meta.mapperDefinition = xml.tag.attr["mapper"];
				}
				;
				xml.onStartTag["fieldtype"] = (ElementParser xml)
				{
					with (xml.tag)
					{
						auto ftName = attr["name"];
						ftype[ftName] = new FieldType(attr["name"], attr["type"]);
						if ("pattern" in attr)
							ftype[ftName].meta.pattern = attr["pattern"];
						if ("format" in attr)
							ftype[ftName].meta.format = attr["format"];
						if (attr.get("preconv", "") == "overpunch")
							ftype[ftName].meta.preConv = &overpunch;
						with (ftype[ftName].meta)
						{
							log.log(LogLevel.INFO, MSG056, name, stringType, pattern, format);
						}
					}
				}
				;
				xml.onStartTag["record"] = (ElementParser xml)
				{
					recName = xml.tag.attr["name"];
					if ("root" in xml.tag.attr)
					{
						recName = buildFieldNameWhenRoot(recName, xml.tag.attr["root"]);
					}
					auto record = new Record(recName, xml.tag.attr["description"]);
					record.meta.section = to!bool(xml.tag.attr.get("section", "false"));
					this ~= record;
					stat.nbRecs[recName] = 0;
				}
				;
				xml.onStartTag["field"] = (ElementParser xml)
				{
					auto type = xml.tag.attr["type"];
					if (!(type in ftype))
					{
						throw new Exception(MSG062.format(type, xml.tag.attr["name"]));
					}
					auto field = new Field(xml.tag.attr["name"], xml.tag.attr["description"], ftype[xml.tag.attr["type"]], to!size_t(xml.tag.attr["length"]));
					if ("pattern" in xml.tag.attr)
						field.pattern = xml.tag.attr["pattern"];
					if ("format" in xml.tag.attr)
						field.fieldFormat = xml.tag.attr["format"];
					this[recName] ~= field;
				}
				;
				xml.parse();
				if (meta.skipField != [])
				{
					this.removeFieldsByRegexFromAllRecords(meta.skipField);
				}
				log.log(LogLevel.INFO, MSG023, xmlFile, this.size);
			}
			string buildFieldNameWhenRoot(string recName, string rootName)
			{
				immutable fmt = "%s_%s";
				return fmt.format(recName, rootName);
			}
			override string toString()
			{
				string s;
				foreach (rec; this)
				{
					s ~= rec.toString;
				}
				return s;
			}
			void keepOnly(string[][string] recordMap)
			{
				foreach (e; recordMap.byKeyValue)
				{
					if (e.value.length == 0 || e.value[0] == "*")
						continue;
					this[e.key].keepOnly(e.value);
				}
				this[].filter!((e) => !(e.name in recordMap)).each!((e) => e.meta.skipRecord = true);
			}
			void keepOnly(in string list, in string separator)
			{
				string[][string] recordMap;
				auto recAndFields = splitIntoTags(list, separator);
				foreach (e; recAndFields)
				{
					auto data = e.split(":");
					auto recName = data[0].strip;
					if (!(recName in this))
					{
						throw new Exception(MSG055.format(recName));
					}
					auto fieldList = array(data[1].split(",").map!((e) => e.strip));
					recordMap[recName] = fieldList;
				}
				keepOnly(recordMap);
				log.info(MSG077, recordMap);
			}
			void removeFieldsByNameFromAllRecords(string[] fieldList)
			{
				fieldList.each!((name) => enforce(isFieldInLayout(name), MSG054.format(name, meta.file)));
				foreach (rec; this)
				{
					foreach (name; fieldList)
					{
						if (name in rec)
							rec.remove(name);
					}
				}
			}
			void removeFieldsByRegexFromAllRecords(string[] fieldListRegex)
			{
				foreach (rec; this)
				{
					foreach (re; fieldListRegex)
					{
						auto matched = rec.names.filter!((fname) => !matchFirst(fname, regex(re)).empty);
						foreach (fname; matched)
						{
							if (fname in rec)
								rec.remove(fname);
						}
					}
				}
			}
			void validate()
			{
				bool validates = true;
				foreach (rec; this)
				{
					if (rec.length != meta.length)
					{
						validates = false;
						log.log(LogLevel.WARNING, MSG034, rec.name, rec.length, meta.length);
					}
				}
				if (validates)
					log.log(LogLevel.INFO, MSG035, meta.file);
			}
			bool isFieldInLayout(string fieldName)
			{
				foreach (rec; this)
				{
					if (fieldName in rec)
						return true;
				}
				return false;
			}
		}
	}
}
