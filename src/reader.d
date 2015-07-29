/**
 * Authors: Alain Viguier
 * Date: 03/04/2015
 * Version: 0.1
 */
module rbf.reader;

import std.stdio;
import std.file;
import std.string;
import std.conv;
import std.exception;
import std.regex;


import rbf.field;
import rbf.record;
import rbf.format;

//import util.common;

// definition of useful aliases
alias GET_RECORD_FUNCTION = string function(string);   /// alias for a function pointer which identifies a record
alias STRING_MAPPER = void function(Record);           /// alias to a delegate used to change field values


/***********************************
 * RB file reader used to loop on record for a RB-file
 */
class Reader {
	
private:
	
	/// filename to read
	immutable string _rbFile;
	
	/// file handle when opened
	File _fh;
	
	/// list of all records read from XML definition file
	Format _fmt;
	
	/// this function will identify a record name from the line read
	GET_RECORD_FUNCTION _recIdent;
	
	/// regex ignore pattern: don't read those lines matching this regex
	string _ignore_pattern;
	
	/// mapper function
	STRING_MAPPER _mapper;
	
public:	
	/**
	 * creates a new Reader object for rb files
	 *
	 * Params:
	 * 	rbfile = path/name of the file to open
	 *  xmlFile = xml file containing fields & records definitions 
	 *  recIndentifier = function used to return the record identifier
	 */	
	this(string rbFile, string xmlFile, GET_RECORD_FUNCTION recIndentifier)
	{
		// check arguments
		enforce(exists(rbFile), "File %s not found".format(rbFile));		
		enforce(exists(xmlFile), "XML definition file %s not found".format(xmlFile));				
		
		// save file name and opens file for reading
		_rbFile = rbFile;
		
		// open file for reading
		_fh = File(rbFile, "r"); 
		
		// build all records but defining a new format
		_fmt = new Format(xmlFile);
		
		// save record identifier lambda
		_recIdent = recIndentifier;

	}
	
	/// properties
	@property void ignore_pattern(string pattern) { _ignore_pattern = pattern; }
	@property void register_mapper(STRING_MAPPER func) { _mapper = func; }

	/**
	 * used to loop on foreach on all records of the file
	 * 
	 * Examples: foreach (Record rec; rbfile) { writeln(rec); }
	 */	
    int opApply(int delegate(ref Record) dg)
    {
        int result = 0;
        string line, recordName;

		// read each line of the ascii file
        foreach (string line_read; lines(File(_rbFile, "r")))
        {
			// get rid of \n
			line = chomp(line_read);
			
			// if line is matching the ignore pattern, just loop
			if (_ignore_pattern != "" && matchFirst(line, regex(_ignore_pattern))) {
				continue;
			}
			
			// try to fetch corresponding record name for line we've read
			recordName = _recIdent(line);
			
			// record not found ? So loop
			if (recordName !in _fmt.records) {
				writefln("record name <%s> not found!!", recordName);
				continue;
			}
			
			// now we can safely save our values
			// set record value (and fields)
			_fmt[recordName].value = line;
			
			// is a mapper registered? so we need to call it
			if (_mapper) 
				_mapper(_fmt[recordName]);
			
			// save line
			_fmt[recordName].line = line;			
			
			// this is conventional way of opApply()
            result = dg(_fmt[recordName]);
            if (result)
                break;
        }
        return result;
    }
	
	/**
	 * destructor: close the file
	*/
	~this() {
		_fh.close();
	}
	
	/**
	 * read the condition file and return an array of string, one string
	 * per condition
	 */
	/*
	string[] readCondition(string fileName)
	{
		string[] cond;
		
		enforce(exists(fileName), "Condition file %s not found".format(fileName));		

		foreach (string line; File(fileName, "r").lines)
		{
			if (!startsWith(line, "#")) cond ~= line.stripRight();
		}
		
		return cond;
	} */
			
	
}


/**
 * Factory for creating a Reader object based on the type of file to read
 */
/*
Reader ReaderFactory(in InputFormat rbFileType, in string inputFile)
{
	final switch(rbFileType)
	{
		case InputFormat.hot203: return new Reader(inputFile, "xml/hot203.xml", (line => line[0..3] ~ line[11..13]));
		case InputFormat.isr: return new Reader(inputFile, "xml/isr.xml", (line => line[0..2]));
		case InputFormat.prl: return new Reader(inputFile, "xml/prl.xml", (line => "PRL"));
	}
}
*/
		

unittest {
	
	void mapper(Record rec) {
		foreach (f; rec) { f.value = "TTT"; }
	}
	
	auto rbf = new Reader("/home/m330421/data/files/bsp/SE.STO.057.PROD.1505281131", r"/home/m330421/data/local/xml/hot203.xml", (line => line[0..3] ~ line[11..13]));
	
	//auto conditions = rbf.readCondition("conds.txt");
	//writeln(conditions);
	
	rbf.ignore_pattern = "^BKS";
	//rbf.register_mapper = &mapper;
	
	foreach (rec; rbf) {
		//if (rec.matchCondition(conditions)) writeln(rec.toTxt);
		//writeln(rec.toTxt()());
		writeln(rec.toTxt());
	}
	

}
