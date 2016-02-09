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
import rbf.log;
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.options;
import rbf.nameditems;
import rbf.stat;

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
	string ignoreLinePattern;                   /// in some case, we need to get rid of some lines. This pattern
                                                /// gives the regex for this
	string[] skipField;						    /// list of field names (comma separated) to systematically skip when reading
	MapperFunc mapper;						    /// function which identifies a record name from a string
	string mapperDefinition;			        /// mapper as declared in the XML file
}

/***********************************
 * This class build the list of records and fields from an XML definition file
 */
class Layout : NamedItemsContainer!(Record, false, LayoutMeta) 
{

private:

    // used to create the hash function from its definition. It maps a line read from the input rb-file
    // to a string value which could be viewed as a hash value, found in the layout definition file
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

			// 1-order function: just a slice of the input string
			case 1:
				auto m1 = matchAll(m.captures[2], r1);
				meta.mapper = (TVALUE x) => x[
					to!size_t(m1.captures[1]) .. to!size_t(m1.captures[2])
				];
				break;

			// 2-order function: a concatenation of 2 slices
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

    // as in layout file the fieldtypes are declared first, we need to keep those when reading
    // the layout file 
	FieldType[string] ftype;

	/**
	 * create all records based on the XML file structure
	 *
	 * Params:
	 *	xmlFile = name of the record/field definition lista a.k.a layout file
	 */
	this(string xmlFile)
	{
		// check for XML file existence
		enforce(exists(xmlFile), MSG037.format(xmlFile));

		// save layout metadata
		meta.file = xmlFile;
		meta.name = baseName(xmlFile);

		// open XML file and load it into a string
		string xmlData = cast(string)std.file.read(xmlFile);

		// call container constructor from string
		super(baseName(xmlFile));

		/// used to save the record name when we find a <record> tag
		string recName;

		// create a new parser
		auto xml = new DocumentParser(xmlData);

		// read layout <meta> definitions and keep types
		xml.onStartTag["meta"] = (ElementParser xml)
		{
            // save metadata of the structure
            auto recLength         = xml.tag.attr.get("reclength", "0");
            meta.length            = (recLength != "") ? to!ulong(recLength) : 0;
            meta.layoutVersion     = xml.tag.attr.get("version", "");
            meta.ignoreLinePattern = xml.tag.attr.get("ignoreLine", "");
            meta.description       = xml.tag.attr.get("description","");

            // build skip list if any
            auto fields = xml.tag.attr.get("skipField","");
            if (fields != "") 
            {
                meta.skipField = array(fields.split(',').map!(e => e.strip));
            }

            // build mapper which must exist othetwise we can't read a rb-file
            if ("mapper" !in xml.tag.attr || xml.tag.attr["mapper"] == "") 
            {
                throw new Exception(MSG038);
            }

            // now we can build the mapper hash function
            _extractMapper(xml.tag.attr["mapper"]);
            meta.mapperDefinition = xml.tag.attr["mapper"];
        };

		// read <fieldtype> definitions and keep types in the aa
		xml.onStartTag["fieldtype"] = (ElementParser xml)
		{
			// save field type base on its name
			with(xml.tag) 
            {
				auto ftName = attr["name"];

				// store new type
				ftype[ftName] = new FieldType(attr["name"], attr["type"]);

				// set extra features in any: pattern or format
                if ("pattern" in attr) ftype[ftName].meta.pattern  = attr["pattern"];
                if ("format" in attr)  ftype[ftName].meta.format   = attr["format"];

                // preconv is set to overpunch if any
                if (attr.get("preconv","") == "overpunch") ftype[ftName].meta.preConv = &overpunch;

                // log creation of field types
                with(ftype[ftName].meta) 
                {
                    log.log(LogLevel.INFO, MSG056, name, stringType, pattern, format);
                }
			}
		};

		// read <record> definitions and create a new record object
		xml.onStartTag["record"] = (ElementParser xml)
		{
			// save record name
			recName = xml.tag.attr["name"];

            // if root attribute is found, this record is tied to its root. Then
            // its name should be built according this is root. This is because of 
            // some layouts, where record names can be duplicated. So we need to find a way
            // to have unique record names
            if ("root" in xml.tag.attr) 
            {
                recName = buildFieldNameWhenRoot(recName, xml.tag.attr["root"]);
            }

			// create a Record object and store it into our record aa
            auto record = new Record(recName, xml.tag.attr["description"]);

            // sometimes, we need to keep track of the occurence of some records. We use this
            // XML attribute for this purpose
            record.meta.section = to!bool(xml.tag.attr.get("section", "false"));

            // add new record to layout container
            this ~= record;

            // create entry into stat AA
            stat.nbRecs[recName] = 0;
            
		};

		// read <field> definitions, create field and add field to previously created record
		xml.onStartTag["field"] = (ElementParser xml)
		{
			// fetch field type
			auto type = xml.tag.attr["type"];

			// the field type must be defined otherwise it's not possible to continue
			if (type !in ftype) 
            {
				throw new Exception(MSG062.format(type, xml.tag.attr["name"]));
			}

			// now create field object with <field> attributes 
            // now need to check for attribute existence because the layout XML file
            // should have been validated against XSD using a validator
			auto field = new Field(
					xml.tag.attr["name"],
					xml.tag.attr["description"],
					ftype[xml.tag.attr["type"]],
					to!size_t(xml.tag.attr["length"])
			);

            // if a specific pattern defined for this field, override the one of the field type
            if ("pattern" in xml.tag.attr) field.pattern = xml.tag.attr["pattern"];

            // if a specific format defined for this field, override the one of the field type
            if ("format" in xml.tag.attr) field.fieldFormat = xml.tag.attr["format"];

			// finally, add field to our record
			this[recName] ~= field;
		};

		// real XML parsing occurs here
		xml.parse();

		// if any, delete skipped fields from layout
		if (meta.skipField != []) 
        {
			this.removeFieldsByRegexFromAllRecords(meta.skipField);
		}

        // log creation of layout
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
	 * used to create field name when root attribute is found
	 *
	 */
	string buildFieldNameWhenRoot(string recName, string rootName)
    {
        immutable fmt = "%s_%s";
        return fmt.format(recName, rootName);
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
			this[].filter!(e => e.name !in recordMap).each!(e => e.meta.skipRecord = true);
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
		assert(l["COUN"].meta.skipRecord);

		l = new Layout(test_file);
		l.keepOnly(["CONT": ["*"]]);
		assert(l["CONT"] == ["NAME", "AREA", "POPULATION", "DENSITY", "CITY"]);
		assert(l["COUN"].meta.skipRecord);

		l = new Layout(test_file);
		assertThrown(l.keepOnly(["CONT": ["FOO", "POPULATION"], "COUN": ["CAPITAL"]]));
		assertThrown(l.keepOnly(["FOO": ["NAME", "POPULATION"], "COUN": ["CAPITAL"]]));
	}

	/**
	 * keep only fields specified for each record:field in the string
	 *
	 * Params:
     * list = list of separated record:field names
     * separator = string used to split field names
	 *
	 */
	void keepOnly(in string list, in string separator) 
    {
			// list contains a list of records:fields to keep in each record
			// each record:field list is separator by separator variable
			string[][string] recordMap;

			// this is a regex to capture calculated fields
			//static auto reg = regex(r"^(\w+)\((\w+)\)$");

			// build a map from this list. Ex list: "CONT:ID,NAME;COUN:POPULATION"
			// possibly remove empty data
			//auto recAndFields = list.split(separator).remove!(e => e == "").remove!(e => e.startsWith("#"));
			auto recAndFields =  splitIntoTags(list, separator);

            // loop on found fields
			foreach (e; recAndFields) 
            {
				auto data = e.split(":");
				auto recName = data[0].strip;

                // check if record name is in layout
                if (recName !in this)
                {
                    throw new Exception(MSG055.format(recName));
                }

				// build field list
				auto fieldList = array(data[1].split(",").map!(e => e.strip));

				// look up each field
                /*
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
                */

                // save field list
				recordMap[recName] = fieldList;
			}

			// call overloaded func
			keepOnly(recordMap);
            log.info(MSG077, recordMap);

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
		l.keepOnly("CONT: NAME , POPULATION;  COUN: CAPITAL", ";");
		assert(l["CONT"] == ["NAME", "POPULATION"]);
		assert(l["COUN"] == ["CAPITAL"]);
	}

	/**
	 * for each record, remove each field in the list.
	 *
	 * Params:
	 *	fieldList = list of field names to get rid of in each record
	 */
	void removeFieldsByNameFromAllRecords(string[] fieldList) 
    {
		// check first if all fields are in layout
		fieldList.each!(
			name => enforce(isFieldInLayout(name), MSG054.format(name, meta.file))
		);

		// a field might not belong to a record. As the remove() method from container
		// is checking field existence, need to check if each field is in the considered
		// record.
		foreach (rec; this) 
        {
			foreach (name; fieldList) 
            {
				if (name in rec) rec.remove(name);
			}
		}
	}
	///
	unittest {
		auto l = new Layout(test_file);
		l.removeFieldsByNameFromAllRecords(["NAME", "CAPITAL", "POPULATION"]);
		assertThrown(l.removeFieldsByNameFromAllRecords(["FOO"]));
		assert(l["CONT"] == ["AREA", "DENSITY", "CITY"]);
		assert(l["COUN"] == []);
	}

	/**
	 * for each record, remove each field in the list when name is matching the regex
	 *
	 * Params:
	 *	fieldListRegex = list of field name regexes to get rid of in each record
	 */
	void removeFieldsByRegexFromAllRecords(string[] fieldListRegex) 
    {
		// a field might not belong to a record. As the remove() method from container
		// is checking field existence, need to check if each field is in the considered
		// record.
		foreach (rec; this) 
        {
			foreach (re; fieldListRegex) 
            {
                auto matched = rec.names.filter!(fname => !matchFirst(fname, regex(re)).empty);
                // foreach matched field name, delete it
                foreach (fname; matched)
                {
                    // need to check first if field has not been already deleted from record
                    // this could be the case (e.g.: FILL)
                    if (fname in rec) rec.remove(fname);
                }
			}
		}
	}
	/**
	 * validate syntax: check if record length is matching file length
	 * is not in the record, just loop
	 */
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

	/**
	 * return true if field is in any record of the layout file
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

	l.removeFieldsByNameFromAllRecords(["NAME", "POPULATION"]);
	assert(l.isFieldInLayout("DENSITY"));
	assert(!l.isFieldInLayout("FOO"));
}
