
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
	Hot203Document[string] docs;
	Hot203Document doc, primary;
	string tdnr; // current TDNR found
	Transaction trx;
	
	auto reader = new Reader(argv[1], r"/home/m330421/data/local/xml/hot203.xml", (line => line[0..3] ~ line[11..13]));
	reader.register_mapper = &overpunch;

	foreach (rec; reader) 
	{
		//writeln(rec.name);
		switch (rec.name)
		{
			// Transaction Header Record
			case "BKT06":
				break;
				
				
			// Ticket/Document Identification Record
			case "BKS24":
				// build new doc based on what is found in BKS24
				doc = new Hot203Document(rec.TDNR, rec.CDGT);

				// save current tdnr for future use if it's a primary
				if (rec.CJCP == "") {
					primary = doc;

					// from in other values
					doc.fromBKS24(rec);
				}
				// if it's a CNJ, keep track of its father
				else {
					// from in other values
					doc.fromBKS24(rec, primary.ticket_number);

					// add TDNR to our father
					primary.addCnjTicket(rec.TDNR);
				}



				// save record in our map
				docs[rec.TDNR] = doc;

				break;
			// Qualifying Issue Information for Sales Transactions Record
			case "BKS46":
				docs[rec.TDNR].fromBKS46(rec);
				break;
			// Itinerary Data Segment Record
			case "BKI63":
				docs[rec.TDNR].fromBKI63(rec);
				break;
			// Additional Information - Passenger Record
			case "BAR65":
				docs[rec.TDNR].fromBAR65(rec);
				break;
			// Additional Information - Form of Payment Record
			case "BAR66":
				docs[rec.TDNR].fromBAR66(rec);
				break;
			// Fare Calculation Record
			case "BKF81":
				docs[rec.TDNR].fromBKF81(rec);
				break;
			// Form of Payment Record
			case "BKP84":
				//docs[rec.TDNR].fromBKP84(rec);
				break;
			// STD/Document Amounts Record
			case "BKS30":
				docs[rec.TDNR].fromBKS30(rec);
				break;
			default:
				break;

		}
	}

	// print out documents
	foreach (doc; docs) {
		if (doc.id.doc_type == "TKTT")
			doc.display();
		writeln();
	}

}
