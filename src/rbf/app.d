
import std.stdio;
import std.file;
import std.string;


import rbf.field;
import rbf.record;
import rbf.format;
import rbf.reader;
import rbf.writer;

import rbf.hot.overpunch;

void main(string[] argv)
{
	
	auto reader = new Reader("/home/m330421/data/files/bsp/test1", r"/home/m330421/data/local/xml/hot203.xml", (line => line[0..3] ~ line[11..13]));
	reader.register_mapper = &overpunch;

	foreach (rec; reader) 
	{
		// rename fields if any
		writeln(rec.toTxt());
	}

}
