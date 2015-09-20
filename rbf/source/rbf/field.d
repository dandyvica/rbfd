module rbf.field;

import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;

import rbf.fieldtype;

/***********************************
 *This field class represents a field as found
 * in record-based files
 */
class Field {
private:

	FieldType _fieldType; 		        /// enum type of the field
	string _name;					            /// name of the element
	immutable string _description;	  /// description of the element. Ex: Ticket/Document Identification Record
	immutable ulong _length;		      /// length (in bytes) of the field
	immutable string _type;			      /// type as passed to the ctor
	string _rawValue;                 /// pristine value
	string _strValue;				          /// when set, store the value of the field

	ulong _index;					            /// index of the field within its parent record
	ulong _offset;					          /// offset of the field within its parent record from the first field

	ulong _lowerBound;				        /// when adding a field to a record, give
	ulong _upperBound;								/// absolute position within the line read

	byte _valueSign = 1;			      /// sign of the scalar value if any

	immutable ulong _cellLength; 			/// used ot correctly print ascii tables

public:
	/**
 	 * creates a new field object
	 *
	 * Params:
	 * 	name = name of the field
	 *  description = a generally long description of the field
	 *  length = length in bytes of the field. Should be >0
	 *  type = whether the field holds numerical, alphanumerical... data
	 *
	 * Examples:
  	 * -----------------------------------------------------------------------
 	 * auto field1 = new Field('FIELD1', 'Field description', 'A/N', 15);
  	 * -----------------------------------------------------------------------
	 */
	this(in string name, in string description, in string type, in ulong length)
	// verify pre-conditions
	{
		// check arguments
		enforce(length > 0, "field length should be > 0");
		enforce(name != "", "field name should not be empty!");

		// just copy what is passed to constructor
		_name        = name;
		_description = description;
		_length      = length;

		// used to print out text data
		_cellLength = max(_length, _name.length);

		// set type according to what is passed
		_type = type;
		_fieldType = new FieldType(type);
	}

	// copy a field with all its data
	Field dup() {
		auto copied = new Field(_name, _description, _type, _length);

		// both copy _rawValue & _strValue
		copied.value = rawValue;

		// copy other properties
		copied.index      = index;
		copied.offset     = offset;
		copied.sign       = sign;
		copied.lowerBound = lowerBound;
		copied.upperBound = upperBound;

		return copied;
	}

	/// read/write property for name attribute
	@property string name() { return _name; }
	@property void name(string name) { _name = name; }

	/// read property for description attribute
	@property string description() { return _description; }

	/// read property for element type
	@property FieldType fieldType() { return _fieldType; }
	@property string declaredType() { return _type; }

	/// read property for field length
	@property ulong length() { return _length; }

	/// read property for cell length when creating ascii tables
	@property ulong cell_length() { return _cellLength; }

	/// read/write property for field value
	@property string value() { return _strValue; }
	@property T value(T)() { return to!T(_strValue) * sign; }
	@property void value(string s)
	{
		_rawValue = s;
		_strValue = s.strip();
	}

	/// read property for field raw value. Raw value is not stripped
	@property string rawValue() { return _rawValue; }

	/// read/write property for the field index
	@property ulong index() { return _index; }
	@property void index(ulong new_index) { _index = new_index; }

	/// read/write property for the field offset
	@property ulong offset() { return _offset; }
	@property void offset(ulong new_offset) { _offset = new_offset; }

	/// read/write property for the sign field
	@property byte sign() { return _valueSign; }
	@property void sign(byte new_sign) { _valueSign = new_sign; }

	/// read/write property lower/upper bounds
	@property ulong lowerBound() { return _lowerBound; }
	@property ulong upperBound() { return _upperBound; }
	@property void lowerBound(ulong new_bound) { _lowerBound = new_bound; }
	@property void upperBound(ulong new_bound) { _upperBound = new_bound; }

	/**
	 * return a string of Field attributes
	 */
	override string toString() {
		return("name=<%s>, description=<%s>, length=<%u>, type=<%s>, lower/upperBound=<%u:%u>, value=<%s>, offset=<%s>, index=<%s>"
			             .format(name, description, length, fieldType, lowerBound, upperBound, value, offset, index));
	}

	/**
	 * test if field value matches condition using the operator.
	 *
	 *  Example: FIELD1 = TEST
	 */
	bool isFieldFilterMatched(in string op, in string rvalue)
	{
		return _fieldType.testFieldFilter(value, op, rvalue);
	}

}



import std.exception;
unittest {
	writefln("-------------------------------------------------------------");
	writeln(__FILE__);
	writefln("-------------------------------------------------------------");

	// check wrong arguments
	assertThrown(new Field("","Ticket/Document Number","A", 5));
	assertThrown(new Field("TDNR","Ticket/Document Number","B", 5));
	assertThrown(new Field("TDNR","Ticket/Document Number","A", 0));

	// create new field and check methods
	auto f = new Field("FIELD1","First field","AN",5);

	assert(f.name == "FIELD1");
	assert(f.description == "First field");
	assert(f.length == 5);
	assert(f.type == FieldType.ALPHANUMERICAL);

	// test methods
	f.value = "12345";
	assert(f.value == "12345");

	writeln(f);

	writeln(f.dup());

}
