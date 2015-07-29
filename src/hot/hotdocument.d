import std.stdio;
import std.string;
import std.conv;
import std.traits;

import rbf.record;

template genReadProperty(string pName)
{
	    const char[] genReadProperty = "@property string " ~ pName ~ "() { return _" ~ pName ~ ";}";
}

template genWriteProperty(string pName)
{
	    const char[] genWriteProperty = "@property void " ~ pName ~ "(string " ~ pName ~ ") { _" ~ pName ~ " = " ~ pName ~ "; }";
}

enum TicketIndicator {
	PRIMARY, CONJUNCTION
}

class Transaction {
	string trx_number;			// TRNN
	string trx_ref;				// TREF
	string trx_control_number;		// TCNR
}

// itinerary segment
struct Segment {
	ushort _segment_identifier;		// SEGI
	char _stop_over_code;			// STPO
	string _not_valid_before;		// NBDA
	string _not_valid_after;		// NADA
}

// passenger data
struct Pax {
	string pax_name;			// PXNM
	string pax_additional_data;		// PXDA

	string toString() { 
		return "pax_name: <%s>, pax_additional_data: <%s>".format(pax_name, pax_additional_data);
	}
}

// form of payment
struct Fop {
	string fop_seqnum;			// FPSN
	string fop_info;			// FPIN

	string toString() { 
		return "fop_seqnum: <%s>, fop_info: <%s>".format(fop_seqnum, fop_info);
	}

}

// fare and amounts
struct Fare {
	float commissionable_amount;		// COBL
	float net_fare_amount;			// NTFA

	float doc_amount;			// TDAM
	string currency;			// CUTP

	string toString() {
		return "doc_amount: <%f>, currency: <%s>".format(doc_amount, currency);
	}

}

// EMD data
struct EmdData {
	// BMP70
	string reason_for_issuance_description;		// RFID
	string reason_for_issuance_code;		// RFIC
	// BMP71
	string in_cnx_with;				// ICDN
	string in_cnx_with_check_digit;			// CDGT 
	// BMP72
	string amount_in_letters;			// AMIL
	// BMP73
	string optional_agency_info;			// OAAI
	// BMP74??
	// BMP75
	ushort emd_coupon_number;			// EMCP
	float emd_coupon_value;				// EMCV
	// CUTP in Doc
	string emd_related_ticket_number;		// EMRT
	string emd_related_coupon_number;		// EMRC
	string emd_reason_issuance_code;		// EMRC
	string emd_reason_issuance_subcode;		// EMSC
	// BMP76
	string emd_remarks;				// EMRM
}

// fare calculation data
struct FareCal {
	ushort fare_cal_number;				// FRCS
	string fare_cal_area;				// FRCA

	string toString() {
		return "fare_cal_number: %d, fare_cal_area: <%s>".format(fare_cal_number, fare_cal_area);
	}
}

// Tax data
struct Tax {
	string tax_fee_type;				// TMFT
	float tax_fee_amount;				// TMFA
	string currency;				// CUTP;

	this(string type, string amount) {
		tax_fee_type = type;
		tax_fee_amount = to!float(amount);
	}

	string toString() {
		return "tax_fee_type: <%s>, tax_fee_amount: <%f>, currency: <%s>".format(tax_fee_type, tax_fee_amount, currency);
	}
}

// currency data
struct Currency {
	string currency;				// CUTP;
}




class HotDocument {
private:
	//------------------------------------------------------------------------------
	// from BKS24 : Ticket/Document Identification Record
	//------------------------------------------------------------------------------
	string _document_number;		// TDNR
	string _check_digit;			// CDGT

	string _date_of_issue;			// DAIS

	string _coupon_use_indicator;		// CPUI
	string _conjonction_indicator;		// CJCP;
	//TicketIndicator _cnj_indicator;		// ADDED

	string _pnr_ref;			// PNRR

	//------------------------------------------------------------------------------
	// from BKS46 : Qualifying Issue Information for Sales Transactions Record
	//------------------------------------------------------------------------------
	string _original_issue_information;	// ORIN
	string _endorsements;			// ENRS

	//------------------------------------------------------------------------------
	// from BKS65 : Additional Information - Passenger Record
	//------------------------------------------------------------------------------
	Pax _pax;

	//------------------------------------------------------------------------------
	// from BAR66 : Additional Information - Form of Payment Record
	//------------------------------------------------------------------------------
	Fop _fop;

	//------------------------------------------------------------------------------
	// from BKP81 : Fare Calculation Record
	//------------------------------------------------------------------------------
	FareCal _fareCal;

	//------------------------------------------------------------------------------
	// from BKS30 : STD/Document Amounts Record
	//------------------------------------------------------------------------------
	Fare _fare;

	//------------------------------------------------------------------------------
	// from BKS30 : STD/Document Amounts Record
	//------------------------------------------------------------------------------
	Tax[string] _taxes;
public:
	this(string tdnr, string cdgt)
	{
		_document_number = tdnr;
		_check_digit = cdgt;
	}

	// display document data
	void display() {
		writefln("Document number: <%s>-<%s>", _document_number, _check_digit);
		writefln("\tdate_of_issue: <%s>, coupon_use_indicator: <%s>, conjonction_indicator: <%s>",
			_date_of_issue, _coupon_use_indicator, _conjonction_indicator);
		writefln("\t%s", _pax);
		writefln("\t%s", _fop);
		writefln("\t%s", _fareCal);
		writefln("\t%s", _fare);

		writeln("\tTaxes:");
		foreach (tax; _taxes) {
			writefln("\t\t%s", tax);
		}

	}
	// read properties
	mixin(genReadProperty!("document_number"));
	mixin(genReadProperty!("check_digit"));
	mixin(genReadProperty!("coupon_use_indicator"));
	mixin(genReadProperty!("date_of_issue"));
	mixin(genReadProperty!("pnr_ref"));

	mixin(genReadProperty!("original_issue_information"));
	mixin(genReadProperty!("endorsements"));


	// write properties
	mixin(genWriteProperty!("coupon_use_indicator"));
	//mixin(genWriteProperty!("conjonction_indicator"));
	@property void conjonction_indicator(string cnj) {
		_conjonction_indicator = cnj;
		//_cnj_indicator = (cnj == "") ? TicketIndicator.PRIMARY : TicketIndicator.CONJUNCTION;
	}
	mixin(genWriteProperty!("date_of_issue"));
	mixin(genWriteProperty!("pnr_ref"));

	mixin(genWriteProperty!("original_issue_information"));
	mixin(genWriteProperty!("endorsements"));


	// fill from record types
	void fillBKS24(Record rec) {
		_coupon_use_indicator = rec.CPUI;
		_conjonction_indicator = rec.CJCP;
		_date_of_issue = rec.DAIS;
		_pnr_ref = rec.PNRR;
	}

	void fillBKS46(Record rec) {
		_original_issue_information = rec.ORIN;
		_endorsements = rec.ENRS;
	}

	void fillBAR65(Record rec) {
		_pax.pax_name = rec.PXNM;
		_pax.pax_additional_data = rec.PXDA;
	}

	void fillBAR66(Record rec) {
		_fop.fop_seqnum = rec.FPSN;
		_fop.fop_info = rec.FPIN;
	}

	void fillBKF81(Record rec) {
		_fareCal.fare_cal_number = to!ushort(rec.FRCS);
		_fareCal.fare_cal_area = rec.FRCA;
	}

	void fillBKS30(Record rec) {
		_fare.doc_amount = to!float(rec.TDAM);
		_fare.currency = rec.CUTP;

		// taxes
		_taxes[rec.TMFT(0)] = Tax(rec.TMFT(0), rec.TMFA(0));
		_taxes[rec.TMFT(0)].currency = rec.CUTP;
		_taxes[rec.TMFT(1)] = Tax(rec.TMFT(1), rec.TMFA(1));
	}
	// auto generate string output from class fields
	/*
	override string toString() {
		string[] s;
		foreach (class_field; FieldNameTuple!HotDocument)
		{
			s ~= class_field ~ "=<" ~ mixin("this." ~ class_field) ~ ">";
		}
		return join(s,",");
	}
	*/

}
