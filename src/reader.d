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


import rbf.field;
import rbf.record;
import rbf.format;

//import util.common;


alias GetRecordFunc = string function(string);   /// alias for a function pointer which identifies a record

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
	GetRecordFunc _recIdent;
	
public:	
	/**
	 * creates a new Reader object for rb files
	 *
	 * Params:
	 * 	rbfile = path/name of the file to open
	 *  xmlFile = xml file containing fields & records definitions 
	 *  recIndentifier = function used to return the record identifier
	 */	
	this(string rbFile, string xmlFile, GetRecordFunc recIndentifier)
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

	/**
	 * used to loop on foreach on all records of the file
	 * 
	 * Examples: foreach (Record rec; rbfile) { writeln(rec); }
	 */	
    int opApply(int delegate(ref Record) dg)
    {
        int result = 0;
        string s, recordName;

        foreach (string line; lines(_fh))
        {
			// get rid of \n
			s = chomp(line);
			
			// fetch corresponding record name for s
			recordName = _recIdent(s);
			
			// now we can safely save our values
			_fmt[recordName].value = s;
			
			// this is conventional way of opApply
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
	
	auto rbf = new Reader("/home/m330421/data/files/bsp/SE.STO.057.PROD.1505281131", r"/home/m330421/data/local/xml/hot203.xml", (line => line[0..3] ~ line[11..13]));
	//auto rbf = ReaderFactory("hot203", r"..\..\..\data\hot\BSP~~~~~~098961");
	
	//auto conditions = rbf.readCondition("conds.txt");
	//writeln(conditions);
	
	foreach (rec; rbf) {
		//if (rec.matchCondition(conditions)) writeln(rec.toTxt);
		writeln(rec.toTxt());
	}
	

}
