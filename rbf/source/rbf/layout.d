module rbf.layout;
pragma(msg, "========> Compiling module ", __MODULE__);

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
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.nameditems;

version(unittest) 
{
	immutable test_file = "./test/world_data.xml";
}

/// useful alias for defining mapper
alias MapperFunc = string delegate(TVALUE);

/// layout and config classes share core same data. So this mixin is useful
/// for boilerplate
mixin template LayoutCore()
{
	string name;									/// layout moniker
	string description;						        /// layout description
	string file;									/// layout XML file with path
}

struct LayoutMeta 
{
	mixin LayoutCore;							/// basic data
	ulong length;							    /// optional layout length
	string layoutVersion;					    /// layout version found in XML file
	string ignoreLinePattern;                   /// in some case, we need to get rid of some lines
	string[] skipField;						    /// field names to systematically skip
	MapperFunc mapper;						    /// function which identifies a record name from a string
	string mapperDefinition;			        /// as defined in the XML file
}

/***********************************
 * This class build the list of records and fields from an XML definition file
 */
class Layout : NamedItemsContainer!(Record, false, LayoutMeta) 
{

private:

	void _extractMapper(string mapper) 
    {
		// regexes to catch mapper data
		auto r1 = regex(r"(\d+)\.\.(\d+)");
		auto r2 = regex(r"(\d+)\.\.(\d+)\s*,\s*(\d+)\.\.(\d+)");

		// extract mapper type & arguments
		auto mapperReg = regex(r"^type:(\d)\s+map:\s*([\w\.,]+)\s*$");
		auto m = matchAll(mapper, mapperReg);
		auto funcType = to!byte(m.captures[1]);

		switch(funcType)
		{
			// constant function == 0 order function
			case 0:
				meta.mapper = (TVALUE x) => m.captures[2];
				break;

			// 1-order function
			case 1:
				auto m1 = matchAll(m.captures[2], r1);
				meta.mapper = (TVALUE x) => x[
					to!size_t(m1.captures[1]) .. to!size_t(m1.captures[2])
				];
				break;

			// 2-order function
			case 2:
				auto m2 = matchAll(m.captures[2], r2);
				meta.mapper = (TVALUE x) =>
					x[to!size_t(m2.captures[1]) .. to!size_t(m2.captures[2])] ~
					x[to!size_t(m2.captures[3]) .. to!size_t(m2.captures[4])];
				break;

			default:
				throw new Exception(MSG036.format(funcType, meta.file));
		}
	}

public:

	FieldType[string] ftype;

	/**
	 * create all records based on the XML file structure
	 *
	 * Params:
	 *	xmlFile = name of the record/field definition list
	 */
	this(string xmlFile)
	{
		// check for XML file existence
		enforce(exists(xmlFile), MSG037.format(xmlFile));

		// save meta
		meta.file = xmlFile;
		meta.name = baseName(xmlFile);

		// open XML file and load it into a string
		string xmlData = cast(string)std.file.read(xmlFile);

		// call constructor from string
		super(baseName(xmlFile));

		/// to save the record name when we find a <record> tag
		string recName;

		// create a new parser
		auto xml = new DocumentParser(xmlData);

		// read <meta> definitions and keep types
		xml.onStartTag["meta"] = (ElementParser xml)
		{
            // save metadata of the structure
            meta.length            = to!ulong(xml.tag.attr.get("reclength", "0"));
            meta.layoutVersion     = xml.tag.attr.get("version", "");
            meta.ignoreLinePattern = xml.tag.attr.get("ignoreLine", "");
            meta.description       = xml.tag.attr.get("description","");

            // build skip list if any
            auto fields = xml.tag.attr.get("skipField","");
            if (fields != "") 
            {
                meta.skipField = array(fields.split(',').map!(e => e.strip));
            }

            // build mapper if any
            if ("mapper" !in xml.tag.attr || xml.tag.attr["mapper"] == "") 
            {
                throw new Exception(MSG038);
            }
            _extractMapper(xml.tag.attr["mapper"]);
            meta.mapperDefinition = xml.tag.attr["mapper"];
        };

		// read <fieldtype> definitions and keep types
		xml.onStartTag["fieldtype"] = (ElementParser xml)
		{
			// save field type base on its name
			with(xml.tag) 
            {
				auto ftName = attr["name"];

				// store new type
				ftype[ftName] = new FieldType(attr["name"], attr["type"]);

				// set extra features in any
				ftype[ftName].meta.pattern      = attr.get("pattern", "");
				ftype[ftName].meta.format       = attr.get("format", "");

                // preconv is set to overpunch if any
                if (attr.get("preconv","") == "overpunch") ftype[ftName].meta.preConv = &overpunch;
			}
		};

		// read <record> definitions and create a new record object
		xml.onStartTag["record"] = (ElementParser xml)
		{
			// save record name
			recName = xml.tag.attr["name"];

			// create a Record object and store it into our record aa
			this  ~= new Record(recName, xml.tag.attr["description"]);
		};

		// read <field> definitions, create field and add field to previously created record
		xml.onStartTag["field"] = (ElementParser xml)
		{
			// fetch field type
			auto type = xml.tag.attr["type"];

			// check whether type is defined
			if (type !in ftype) 
            {
				throw new Exception("error: type %s is not defined!!".format(type));
			}

			// otherwise just create with fetched type
			auto field = new Field(
					xml.tag.attr["name"],
					xml.tag.attr["description"],
					ftype[xml.tag.attr["type"]],
					to!uint(xml.tag.attr["length"])
			);

			// add field to our record
			this[recName] ~= field;
		};

		// parse XML here
		xml.parse();

		// if any, delete skipped fields from layout
		if (meta.skipField != []) 
        {
			this.removeFromAllRecords(meta.skipField);
		}

        // log
        log.log(LogLevel.INFO, MSG023, xmlFile, this.size);
	}
	///
	unittest {
		auto l = new Layout(test_file);
		assertThrown(new Layout("foo.xml"));
	}

	///
	unittest {
		auto l = new Layout(test_file);
		assert("COUN" in l);
		assert("CONT" in l);
		assert("FOO" !in l);
	}

	/**
	 * record definition for all records found
	 *
	 */
	override string toString() 
    {
		string s;
		foreach (rec; this) { s ~= rec.toString; }
		return s;
	}

	/**
	 * keep only fields specified for each record in the map
	 *
	 * Params:
	 *	recordMap = associate array (key=record name, value=array of field names)
	 *
	 */
	void keepOnly(string[][string] recordMap) 
    {
			// recordMap contains a list of fields to keep in each record
			// the key of recordMap is a record name
			// for all those records, keep only those fields provided
			foreach (e; recordMap.byKeyValue) 
            {
				// "*" means keep all fields for this record
				if (e.value.length == 0 || e.value[0] == "*")  continue;

				// otherwise, keep only those records provided
				this[e.key].keepOnly(e.value);
			}

			// for all other records not provided, just get rid of them
			this[].filter!(e => e.name !in recordMap).each!(e => e.meta.skip = true);
	}
	///
	unittest {
		auto l = new Layout(test_file);
		l.keepOnly(["CONT": ["NAME", "POPULATION"], "COUN": ["CAPITAL"]]);
		assert(l["CONT"] == ["NAME", "POPULATION"]);
		assert(l["COUN"] == ["CAPITAL"]);

		l = new Layout(test_file);
		l.keepOnly(["CONT": ["NAME", "POPULATION"]]);
		assert(l["CONT"] == ["NAME", "POPULATION"]);
		assert(l["COUN"].meta.skip);

		l = new Layout(test_file);
		l.keepOnly(["CONT": ["*"]]);
		assert(l["CONT"] == ["NAME", "AREA", "POPULATION", "DENSITY", "CITY"]);
		assert(l["COUN"].meta.skip);

		l = new Layout(test_file);
		assertThrown(l.keepOnly(["CONT": ["FOO", "POPULATION"], "COUN": ["CAPITAL"]]));
		assertThrown(l.keepOnly(["FOO": ["NAME", "POPULATION"], "COUN": ["CAPITAL"]]));
	}

	/**
	 * keep only fields specified for each record:field in the string
	 *
	 * Params:
	 *
	 */
	void keepOnly(in string list, in string separator) 
    {
			// list contains a list of records:fields to keep in each record
			// each record:field list is separator by separator variable
			string[][string] recordMap;

			// this is a regex to capture calculated fields
			static auto reg = regex(r"^(\w+)\((\w+)\)$");

			// build a map from this list. Ex list: "CONT:ID,NAME;COUN:POPULATION"
			// possibly remove empty data
			auto recAndFields = list.split(separator).remove!(e => e == "");

			foreach (e; recAndFields) 
            {
				auto data = e.split(":");
				auto recName = data[0].strip;

				// build field list
				auto fieldList = array(data[1].split(",").map!(e => e.strip));

				// look up each field
				foreach (f; fieldList) 
                {
					// calculated field?
					auto m = matchAll(f, reg);

					// match? then field is a "fake" field
					if (!m.empty) 
                    {
						//writeln(m);
						auto underlyingFieldName = m.captures[2];
						auto underlyingFieldType = this[recName][underlyingFieldName][0].type;
						this[recName] ~= new Field(f, f, underlyingFieldType, f.length);
					}

				}

				recordMap[recName] = fieldList;
			}

			// call overloaded func
			keepOnly(recordMap);

	}
	///
	unittest {
		auto l = new Layout(test_file);
		l.keepOnly("CONT: NAME , POPULATION;  COUN: CAPITAL", ";");
		assert(l["CONT"] == ["NAME", "POPULATION"]);
		assert(l["COUN"] == ["CAPITAL"]);

		l = new Layout(test_file);
		l.keepOnly(cast(string)std.file.read("./test/test_fields.lst"), "\n");
		assert(l["CONT"] == ["NAME", "POPULATION"]);
		assert(l["COUN"] == ["CAPITAL"]);

		l = new Layout(test_file);
		l.keepOnly("CONT: NAME , POPULATION;  COUN: CAPITAL, SUM(NAME)", ";");
		assert(l["CONT"] == ["NAME", "POPULATION"]);
		assert(l["COUN"] == ["CAPITAL", "SUM(NAME)"]);
	}

	/**
	 * for each record, remove each field in the list.
	 *
	 * Params:
	 *	fieldList = list of fields to get rid of in each record
	 */
	void removeFromAllRecords(string[] fieldList) 
    {
		// check first if all fields are in layout
		fieldList.each!(
			name => enforce(isFieldInLayout(name), "error: field %s in not in layout %s".format(name, meta.file))
		);

		// a field might not belong to a record. As the remove() method from container
		// is checking field existence, need to check if each field is in the considered
		// record.
		foreach (rec; this) {
			foreach (name; fieldList) {
				if (name in rec) rec.remove(name);
			}
		}
	}
	///
	unittest {
		auto l = new Layout(test_file);
		l.removeFromAllRecords(["NAME", "CAPITAL", "POPULATION"]);
		assertThrown(l.removeFromAllRecords(["FOO"]));
		assert(l["CONT"] == ["AREA", "DENSITY", "CITY"]);
		assert(l["COUN"] == []);
	}

	/**
	 * validate syntax: check if record length is matching file length
	 * is not in the record, just loop
	 */
	void validate() 
    {
		bool validates = true;
		foreach (rec; this) {
			if (rec.length != meta.length) {
				validates = false;
                log.log(LogLevel.WARNING, MSG034, rec.name, rec.length, _length);
			}
		}
		if (validates) 
                log.log(LogLevel.WARNING, MSG035, meta.file);
	}

	/**
	 * return true if field is in any record of layout
	 */
	bool isFieldInLayout(string fieldName)
    {
		foreach (rec; this) 
        {
				if (fieldName in rec) return true;
		}
		return false;
	}

}
///
unittest {
	writeln("========> testing ", __FILE__);

	auto l = new Layout(test_file);

	assert(l.meta.description == "Continents, countries, cities");
	assert(l.meta.layoutVersion == "1.0");

	// ID field is not there
	assert(l.meta.skipField == ["ID"]);
	assert(!l.isFieldInLayout("ID"));
	assert(!l.isFieldInLayout("ID2"));

	l.removeFromAllRecords(["NAME", "POPULATION"]);
	assert(l.isFieldInLayout("DENSITY"));
	assert(!l.isFieldInLayout("FOO"));
}
