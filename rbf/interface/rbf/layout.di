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
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.nameditems;
version (unittest)
{
	immutable test_file = "./test/world_data.xml";
}
alias MapperFunc = string delegate(string);
enum LayoutSource 
{
	L_FILE,
	L_STRING,
}
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
					meta.mapper = (string x) => m.captures[2];
					break;
				}
				case 1:
				{
					auto m1 = matchAll(m.captures[2], r1);
					meta.mapper = (string x) => x[to!size_t(m1.captures[1])..to!size_t(m1.captures[2])];
					break;
				}
				case 2:
				{
					auto m2 = matchAll(m.captures[2], r2);
					meta.mapper = (string x) => x[to!size_t(m2.captures[1])..to!size_t(m2.captures[2])] ~ x[to!size_t(m2.captures[3])..to!size_t(m2.captures[4])];
					break;
				}
				default:
				{
					throw new Exception("error: unknown mapper lambda <%d> in layout <%s>".format(funcType, meta.file));
				}
			}
		}
		public 
		{
			FieldType[string] ftype;
			this(string xmlFile)
			{
				enforce(exists(xmlFile), "XML definition file %s not found".format(xmlFile));
				meta.file = xmlFile;
				meta.name = baseName(xmlFile);
				string xmlData = cast(string)std.file.read(xmlFile);
				super(baseName(xmlFile));
				string recName = "";
				auto xml = new DocumentParser(xmlData);
				meta.length = to!ulong(xml.tag.attr.get("reclength", "0"));
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
					throw new Exception("error: mapper function is not defined in layout");
				}
				_extractMapper(xml.tag.attr["mapper"]);
				meta.mapperDefinition = xml.tag.attr["mapper"];
				xml.onStartTag["fieldtype"] = (ElementParser xml)
				{
					with (xml.tag)
					{
						auto ftName = attr["name"];
						ftype[ftName] = new FieldType(attr["name"], attr["type"]);
						ftype[ftName].meta.pattern = attr.get("pattern", "");
						ftype[ftName].meta.format = attr.get("format", "");
						ftype[ftName].meta.checkPattern = to!bool(attr.get("checkPattern", "false"));
						if (attr.get("preconv", "") == "overpunch")
							ftype[ftName].meta.preConv = &overpunch;
					}
				}
				;
				xml.onStartTag["record"] = (ElementParser xml)
				{
					recName = xml.tag.attr["name"];
					this ~= new Record(recName, xml.tag.attr["description"]);
				}
				;
				xml.onStartTag["field"] = (ElementParser xml)
				{
					auto type = xml.tag.attr["type"];
					if (!(type in ftype))
					{
						throw new Exception("error: type %s is not defined!!".format(type));
					}
					auto field = new Field(xml.tag.attr["name"], xml.tag.attr["description"], ftype[xml.tag.attr["type"]], to!uint(xml.tag.attr["length"]));
					this[recName] ~= field;
				}
				;
				xml.parse();
				if (meta.skipField != [])
				{
					this.removeFromAllRecords(meta.skipField);
				}
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
					if (e.value[0] == "*")
						continue;
					this[e.key].keepOnly(e.value);
				}
				this[].filter!((e) => !(e.name in recordMap)).each!((e) => e.meta.skip = true);
			}
			void keepOnly(string list, string separator)
			{
				string[][string] recordMap;
				auto static reg = regex("^(\\w+)\\((\\w+)\\)$");
				auto recAndFields = list.split(separator).remove!((e) => e == "");
				foreach (e; recAndFields)
				{
					auto data = e.split(":");
					auto recName = data[0].strip;
					auto fieldList = array(data[1].split(",").map!((e) => e.strip));
					foreach (f; fieldList)
					{
						auto m = matchAll(f, reg);
						if (!m.empty)
						{
							auto underlyingFieldName = m.captures[2];
							auto underlyingFieldType = this[recName][underlyingFieldName][0].type;
							this[recName] ~= new Field(f, f, underlyingFieldType, f.length);
						}
					}
					recordMap[recName] = fieldList;
				}
				keepOnly(recordMap);
			}
			void removeFromAllRecords(string[] fieldList)
			{
				fieldList.each!((name) => enforce(isFieldInLayout(name), "error: field %s in not in layout %s".format(name, meta.file)));
				foreach (rec; this)
				{
					foreach (name; fieldList)
					{
						if (name in rec)
							rec.remove(name);
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
						stderr.writefln("Warning: record %s is not matching declared length (%d instead of %d)", rec.name, rec.length, _length);
					}
				}
				if (validates)
					stderr.writefln("Info: layout %s validates!!", meta.file);
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
