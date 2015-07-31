import std.stdio;
import std.string;
import std.conv;
import std.traits;
import std.range;
import std.algorithm;

import rbf.record;

template genReadProperty(string pName)
{
	    const char[] genReadProperty = "@property string " ~ pName ~ "() { return _" ~ pName ~ ";}";
}

template genWriteProperty(string pName)
{
	    const char[] genWriteProperty = "@property void " ~ pName ~ "(string " ~ pName ~ ") { _" ~ pName ~ " = " ~ pName ~ "; }";
}

// useful enums
enum TicketIndicator {
	PRIMARY, CONJUNCTION
}
enum DocumentType {
	TICKET, EMDS, EMDA
}

struct Transaction {
	string trx_number;			// BKT06.TRNN
	string trx_ref;				// BKT06.TREF
	string trx_control_number;		// BKT06.TCNR
	string settlement_authorization_code;	// BKP83.ESAC
	string ticketing_airline;		// BKT06.TACN 
	string client_id;			// BKT06.CLID
	string system_id; 			// BKT06.RPSI
}

// itinerary segment
struct Segment {
	ushort segment_identifier;		// SEGI
	char  stop_over_code;			// STPO
	string not_valid_before;		// NBDA
	string not_valid_after;			// NADA
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
	string fop_seqnum;			// BAR66.FPSN
	string fop_info;			// BAR66.FPIN

	string payment_type;			// FPTP
	string payment_amount;			// FPAM
	string payment_account_number;		// FPAC
	string expiry_date;			// EXDA
	string approval_code;			// APLC
	string invoice_number;			// INVN
	string invoice_date;			// INVD
	string signed_for_amount;		// SFAM
	string remittance_amount;		// RMET
	string currency_type1;			// CUTP
	string currency_type2;			// CUTP
	string card_verification_result;		// CVVR

	string toString() { 
		auto s1 = "fop_seqnum: <%s>, fop_info: <%s>".format(fop_seqnum, fop_info);
		auto s2 = ", payment_type: %s, payment_amount: %s, payment_account_number: %s, expiry_date: %s, approval_code: %s"
			.format(payment_type, payment_amount, payment_account_number, expiry_date, approval_code);
		auto s3  = ", invoice_number: %s, invoice_date: %s, signed_for_amount: %s, remittance_amount: %s"
			.format(invoice_number, invoice_date, signed_for_amount, remittance_amount);
		auto s4 = ", currency_type1: %s, currency_type2: %s, card_verification_result: %s"
			.format(currency_type1, currency_type2, card_verification_result);

		return s1 ~ s2 ~ s3 ~ s4;
	}

}

// fare and amounts
struct Fare {
	float net_fare_amount;			// NTFA

	float doc_amount = 0.0;			// BKS30.TDAM
	float commissionable_amount = 0.0;	// BKS30.COBL
	Currency currency;			// CUTP

	string toString() {
		return "doc_amount: <%.2f>, commissionable_amount: <%.2f>, currency: <%s>".format(doc_amount, commissionable_amount, currency.currency_name);
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
//		return "fare_cal_area: <%s>".format(fare_cal_area);
		return "%s".format(fare_cal_area);
	}
}

// Tax data
struct Tax {
	string tax_fee_type;				// TMFT
	float tax_fee_amount;				// TMFA
	Currency currency;				// CUTP;

/*
	this(string type, string amount) {
		tax_fee_type = type;
		tax_fee_amount = to!float(amount);
	}
*/

	string toString() {
//		return "tax_fee_type: <%s>, tax_fee_amount: <%f>, currency: <%s>".format(tax_fee_type, tax_fee_amount, currency.currency_name);
		return "%.10s\t%.2f\t%.10s".format(tax_fee_type, tax_fee_amount, currency.currency_name);
	}
}

// currency data
struct Currency {
	string currency_name;				// CUTP;

	// extract number of decimals from currency
	ushort decimals() {
		return to!ushort(currency_name[$-1..$]);
	}

	// convert to real amount
	float convert(string amount) {
		return to!float(amount) / 10^^decimals;
	}

	// convert to real amount
	float convert(float amount) {
		return amount / 10^^decimals;
	}
}

// flight data
struct Flight {
	string carrier;					// BKI63.CARR
	string flight_number;				// BKI63.FTNR
	string origin;					// BKI63.ORAC
	string destination;				// BKI63.DSTC
	string flight_dep_date;				// BKI63.FTDA
	string flight_dep_time;				// BKI63.FTDT

	string toString() {
		auto s = "%s %s %s %s %s %s".format(carrier, flight_number, origin, destination, flight_dep_date, flight_dep_time);
		return s;
	}
}

// coupon data
struct Coupon {
	ushort segment_id;				// BKI63.SEGI
	string stop_over_code;				// BKI63.STPO
	string not_valid_before;			// BKI63.NBDA
	string not_valid_after;				// BKI63.NADA
	string booking_designator;			// BKI63.RBKD
	string booking_status;				// BKI63.FBST
	string baggage_allowance;			// BKI63.FBAL

	string ff_ref;					// BKI63.FFRF
	string fare_basis;				// BKI63.FBTD

	// flight data
	Flight flight;

	string toString() {
		auto s = "segment: <%d>, stop_over_code: <%s>, not_valid_before: <%s>, not_valid_after: <%s>";
		s ~= ", booking_designator: <%s>, booking_status: <%s>, baggage_allowance: <%s>, ff_ref: <%s>, fare_basis: <%s>";
		return s.format(segment_id, stop_over_code, not_valid_before, not_valid_after, booking_designator, 
				booking_status, baggage_allowance, ff_ref, fare_basis);
	}
}

struct Agency {
	string iata_number;	// AGTN
}


struct DocumentID {
	immutable string document_number;		// TDNR
	string check_digit;			// CDGT

	string date_of_issue;			// DAIS

	string coupon_use_indicator;		// CPUI
	string conjonction_indicator;		// CJCP;
	//TicketIndicator _cnj_indicator;		// ADDED

	string tour_code;			// TOUR
	string trx_code;			// TRNC
	string true_ond;			// TODC

	string pnr_ref;			// PNRR

	string toString() {
		auto s = "Document number: <%s>-<%s>-<%s>, date_of_issue: <%s>, coupon_use_indicator: <%s>, conjonction_indicator: <%s>";
		s ~= ", tour_code: <%s>, true_ond: <%s>, pnr_ref: <%s>";
		return s.format(document_number, check_digit, trx_code, date_of_issue, coupon_use_indicator, conjonction_indicator,
					tour_code, true_ond, pnr_ref);
	}

	// specific and not in HOT files
	string doc_type;		// whether its a ticket, emds, emda, refund, ...
	string primary_doc_number;	// the doc number of the first ticket in the journey (empty if a primary ticket)
	TicketIndicator ticket_indicator; // whether it's a primary of conjunction ticket
	ushort ticket_index;		// index for the ticket (0=primary, 1 for the first cnj found, ...)

	// list of subsequent tickets
	string[] cnj_tickets;
}

struct SaleInfo {
	string original_issue_information;	// BKS46.ORIN
	string endorsements;			// BKS46.ENRS


	string toString() {
		return "original issue information: <%s>, endorsements/restrictions: <%s>".format(original_issue_information, endorsements);
	}
}


class Hot203Document {
private:
	//------------------------------------------------------------------------------
	// from BKS24 : Ticket/Document Identification Record
	//------------------------------------------------------------------------------
	DocumentID _id;
	Agency _agency;

	//------------------------------------------------------------------------------
	// from BKS46 : Qualifying Issue Information for Sales Transactions Record
	//------------------------------------------------------------------------------
	SaleInfo _sale;

	//------------------------------------------------------------------------------
	// from BKS65 : Additional Information - Passenger Record
	//------------------------------------------------------------------------------
	Pax _pax;

	//------------------------------------------------------------------------------
	// from BKP84 : Form of Payment Record
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
	Tax[] _taxes;

	//------------------------------------------------------------------------------
	// from BKI63 : Itinerary Data Segment Record
	//------------------------------------------------------------------------------
	Coupon[4] _coupon;

	//------------------------------------------------------------------------------
	// from BKT06 : Transaction Header Record
	// from BKP83 : Electronic Transaction Record
	//------------------------------------------------------------------------------
	Transaction _trx;
public:
	this(string tdnr, string cdgt)
	{
		_id.document_number = tdnr;
		_id.check_digit = cdgt;
	}

	// display document data
	void display() {
		writefln("%s", _id);
		writefln("\tPax: %s", _pax);
		writefln("\tFOP: %s", _fop);
		writefln("\tSale:%s", _sale);
		writefln("\t%s", _fare);

		// no taxes for CNJ ticket
		if (_taxes.length != 0) {
			writeln("\tTaxes:");
			foreach (tax; _taxes) {
				writefln("\t\t%s", tax);
			}
			// sum of taxes
			writefln("\t\tSum of taxes: %.2f, TDAM-COBL=%.2f", 	
				reduce!((a, b) => a + b.tax_fee_amount)(0.0, _taxes), _fare.doc_amount-_fare.commissionable_amount);
		}

		writeln("\tCoupons:");
		foreach (cpn; _coupon) {
			if (cpn.segment_id != 0) {
				writefln("\t\t%s", cpn);
				writefln("\t\t%s", cpn.flight);
			}
		}

		// if cnj tickets?
		if (_id.cnj_tickets.length > 0) {
			writefln("\tConjunctions tickets: \n\t\t%s", id.cnj_tickets);
		}
	
		writefln("\tFare calculation:\n\t\t%s", _fareCal);

		// primary reference?
		if (_id.primary_doc_number != "") {
			writefln("\tPrimary ticket: <%s>", _id.primary_doc_number);
		}

	}
	// read properties
	@property DocumentID id() { return _id; }

	@property string ticket_number() { return _id.document_number; }
	/*
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
	*/

	// from from record types
	void fromBKS24(Record rec, in string primary_ticket_number = "") {
		// data from record
		_id.coupon_use_indicator = rec.CPUI;
		_id.conjonction_indicator = rec.CJCP;
		_id.date_of_issue = rec.DAIS;
		_id.pnr_ref = rec.PNRR;
		_id.tour_code = rec.TOUR;
		_id.trx_code = rec.TRNC;
		_id.true_ond = rec.TODC;

		// AGTN is the IATA agency number
		_agency.iata_number = rec.AGTN;

		// set specific data
		_id.doc_type = _id.trx_code;

		// CNJ?
		if (_id.conjonction_indicator == "CNJ") {
			_id.ticket_indicator = TicketIndicator.CONJUNCTION;
			_id.primary_doc_number = primary_ticket_number;
		} 
		// otherwise primary
		else {
			_id.ticket_indicator = TicketIndicator.PRIMARY;
			_id.primary_doc_number = "";
		}
	}

	void fromBKS46(Record rec) {
		_sale.original_issue_information ~= rec.ORIN;
		_sale.endorsements ~= rec.ENRS;
	}

	void fromBAR65(Record rec) {
		_pax.pax_name = rec.PXNM;
		_pax.pax_additional_data = rec.PXDA;
	}

	void fromBAR66(Record rec) {
		_fop.fop_seqnum = rec.FPSN;
		_fop.fop_info = rec.FPIN;
	}

	void fromBKF81(Record rec) {
		//_fareCal.fare_cal_number = to!ushort(rec.FRCS);
		_fareCal.fare_cal_area ~= rec.FRCA;
	}

	void fromBKS30(Record rec) {

		// TDAM is only valid for the first record found
		if (_fare.doc_amount == 0.0) {
			_fare.currency.currency_name = rec.CUTP;
			_fare.doc_amount = _fare.currency.convert(rec.TDAM);
		}

		// same for COBL
		if (_fare.commissionable_amount == 0.0) {
			_fare.commissionable_amount = _fare.currency.convert(rec.COBL);
		}

		// fill taxes if any
		auto tax_name = rec.TMFT(0);
		if (tax_name != "") {
			_taxes ~= Tax();
			_taxes[$-1].currency.currency_name = rec.CUTP;
			_taxes[$-1].tax_fee_type = rec.TMFT(0);
			// currency last digit is the number of decimals to take into account
			_taxes[$-1].tax_fee_amount = _taxes[$-1].currency.convert(rec.TMFA(0));
		}

		tax_name = rec.TMFT(1);
		if (tax_name != "") {
			_taxes ~= Tax();
			_taxes[$-1].currency.currency_name = rec.CUTP;
			_taxes[$-1].tax_fee_type = rec.TMFT(1);
			// currency last digit is the number of decimals to take into account
			_taxes[$-1].tax_fee_amount = _taxes[$-1].currency.convert(rec.TMFA(1));
		}

	}

	void fromBKT06(Record rec) {
		_trx.trx_number = rec.TRNN;
		_trx.trx_ref = rec.TREF;
		_trx.ticketing_airline = rec.TACN;
		_trx.client_id = rec.CLID;
		_trx.system_id = rec.RPSI;
	}

	void fromBKS83(Record rec) {
		_trx.settlement_authorization_code = rec.ESAC;
	}

	void fromBKP84(Record rec) {
		_fop.payment_type = rec.FPTP;
		_fop.payment_amount = rec.FPAM;
		_fop.payment_account_number = rec.FPAC;
		_fop.expiry_date = rec.EXDA;
		_fop.approval_code = rec.APLC;
		_fop.invoice_number = rec.INVN;
		_fop.invoice_date = rec.INVD;
		_fop.signed_for_amount = rec.SFAM;
		_fop.remittance_amount = rec.RMET;
		_fop.currency_type1 = rec.CUTP;
		_fop.currency_type2 = rec.CUTP;
		_fop.card_verification_result = rec.CVVR;
	}

	void fromBKI63(Record rec) {

		auto cpn_id = to!ushort(rec.SEGI);

		
		_coupon[cpn_id-1].segment_id = cpn_id;
		_coupon[cpn_id-1].stop_over_code = rec.STPO;
		_coupon[cpn_id-1].not_valid_before = rec.NBDA;
		_coupon[cpn_id-1].not_valid_after = rec.NADA;
		_coupon[cpn_id-1].booking_designator = rec.RBKD;
		_coupon[cpn_id-1].booking_status = rec.FBST;
		_coupon[cpn_id-1].baggage_allowance = rec.FBAL;
		_coupon[cpn_id-1].ff_ref = rec.FFRF;
		_coupon[cpn_id-1].fare_basis = rec.FBTD;

		// flight data
		_coupon[cpn_id-1].flight.carrier = rec.CARR;
		_coupon[cpn_id-1].flight.flight_number = rec.FTNR;
		_coupon[cpn_id-1].flight.origin = rec.ORAC;
		_coupon[cpn_id-1].flight.destination = rec.DSTC;
		_coupon[cpn_id-1].flight.flight_dep_date = rec.FTDA;
		_coupon[cpn_id-1].flight.flight_dep_time = rec.FTDT;
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

	// keep track of all the cnj tickets
	void addCnjTicket(string cnj_number) {
		_id.cnj_tickets ~= cnj_number;
		_id.ticket_index = to!ushort(_id.cnj_tickets.length);
	}

}
