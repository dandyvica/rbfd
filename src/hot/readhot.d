
import std.stdio;
import std.file;
import std.string;


import rbf.field;
import rbf.record;
import rbf.format;
import rbf.reader;
//import rbf.writer;

import hot.overpunch;
import hot.hotdocument;

void main(string[] argv)
{
	HotDocument[string] docs;
	HotDocument doc;
	string tdnr; // current TDNR found
	
	auto reader = new Reader("/home/m330421/data/files/bsp/SE.STO.057.PROD.1505281131", r"/home/m330421/data/local/xml/hot203.xml", (line => line[0..3] ~ line[11..13]));
	reader.register_mapper = &overpunch;

	foreach (rec; reader) 
	{
		switch (rec.name)
		{
			// Ticket/Document Identification Record
			case "BKS24":
				// save current tdnr for future use
				tdnr = rec.TDNR;

				// build new doc based on what is found in BKS24
				doc = new HotDocument(tdnr, rec.CDGT);

				// fill in other values
				doc.fillBKS24(rec);

				// save record in our map
				docs[rec.TDNR] = doc;
				break;
			// Qualifying Issue Information for Sales Transactions Record
			case "BKS46":
				docs[rec.TDNR].fillBKS46(rec);
				break;
			// Additional Information - Passenger Record
			case "BAR65":
				docs[rec.TDNR].fillBAR65(rec);
				break;
			// Additional Information - Form of Payment Record
			case "BAR66":
				docs[rec.TDNR].fillBAR66(rec);
				break;
			// Fare Calculation Record
			case "BKF81":
				docs[rec.TDNR].fillBKF81(rec);
				break;
			// STD/Document Amounts Record
			case "BKS30":
				docs[rec.TDNR].fillBKS30(rec);
				break;
			default:
				break;

		}
	}

	// print out documents
	foreach (doc; docs) {
		doc.display();
	}

}
