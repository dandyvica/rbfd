module rbf.writers.templatewriter;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.range;
import std.algorithm;
import std.regex;

import rbf.errormsg;
import rbf.log;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;

// regex to find tags
auto reg = regex(r"#\{(\w+)\.(\w+)\}");

// tag pattern
immutable TAG = "#{%s.%s}";

/*********************************************
 * CSV class
 */
class TemplateWriter : Writer 
{
    // save layout internally
    Layout _layout;

    // list of records & fields saved from template file
    string[][string] _templateTags;

    // template file data as a string
    string _tempData;

	this(in string outputFileName)
	{
		super(outputFileName);
    }

    // prepare by building template data
	override void prepare(Layout layout) 
    { 
        // save layout object
         _layout = layout; 

		// check for template file existence
		enforce(exists(outputFeature.templateFile), MSG078.format(outputFeature.templateFile));

        // open file and load data into string
		_tempData = cast(string)std.file.read(outputFeature.templateFile);

        // build the list of records/fields located in this file
        foreach (line; File(outputFeature.templateFile, "r").byLine())
        {
            // find out if tags are found in the template
            foreach (m; matchAll(line, reg))
            {
                //writeln(m);

                if (!m.empty)
                {
                    // save data
                    auto recordName = m.captures[1].idup;
                    auto fieldName  = m.captures[2].idup;

                    // add those data into our dict
                    _templateTags[recordName] ~= fieldName;
                }
            }
        }
        log.info(MSG080, outputFeature.templateFile);
	}

    override void build(string outputFileName) {}

	override void write(Record rec)
	{
        // temp variables
        string tag, data;

        // need to set fresh data each time from template
        string s = _tempData;

        // replace tags with corresponding data
        foreach (e; _templateTags.byKeyValue)
        {
            // loop through fields
            foreach (f; e.value)
            {
                tag = TAG.format(e.key,f);

                // if we use alternate names, fetch fields from unique list
                if (outputFeature.useAlternateName)
                {
                    data = _layout[e.key].getUnique(f).value;
                }
                else
                {
                    data = _layout[e.key].get(f).value;
                }

                // just replace data
                s = s.replace(tag, data);
            }
        }

        // save data to output file
		_fh.write(s);
	}

}
///
unittest {

	writeln("========> testing ", __FILE__);

	import rbf.reader;
	import rbf.layout;

	auto layout = new Layout("./test/world_data.xml");
	auto reader = new Reader("./test/world.data", layout);

	auto writer = writerFactory("./test/world_data.csv", OutputFormat.csv);
	writer.outputFeature.fieldSeparator = "-";

	foreach (rec; reader) { writer.write(rec); }

}
