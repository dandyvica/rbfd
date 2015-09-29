module rbf.field;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.typecons;
import std.exception;

import rbf.fieldtype;

/***********************************
 *This field class represents a field as found
 * in record-based files
 */
class Field {
private:

	FieldType _fieldType; 		        /// type of the field
	string _name;					            /// name of the field
	immutable string _description;	  /// description of the field. Ex: Ticket/Document Identification Record
	immutable ulong _length;		      /// length (in bytes) of the field

	string _rawValue;                 /// pristine value
	string _strValue;				          /// store the string value of the field

	ulong _index;					            /// index of the field within its parent record
	ulong _offset;					          /// offset of the field within its parent record from the first field

	ulong _lowerBound;				        /// when adding a field to a record, give
	ulong _upperBound;								/// absolute position within the line read

	byte _valueSign = 1;			      /// sign of the scalar value if any

	immutable ulong _cellLength; 			/// used ot correctly print ascii tables

public:
	/**
 	 * create a new field object
	 *
	 * Params:
	 * 	name = name of the field
	 *  description = a generally long description of the field
	 *  length = length in bytes of the field. Should be >0
	 *  ftype = FieldType object
	 *
	 */
	this(in string name, in string description, FieldType ftype, in ulong length)
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

		// save field type
		_fieldType = ftype;
	}
	///
	unittest {
		auto field1 = new Field("FIELD1", "Field description", new FieldType("A/N"), 15);
	}

	/// second constructor
	this(in string name, in string description, in string stringType, in ulong length)
	{
		this(name, description, new FieldType(stringType), length);
	}
	///
	unittest {
		assertThrown(new Field("","First field","A", 5));
		assertThrown(new Field("FIELD1","First field","B", 5));
		assertThrown(new Field("FIELD1","First field","A", 0));
		auto field1 = new Field("FIELD1", "Field description", "A/N", 15);
	}

/*
	// copy a field with all its data
	Field dup() {
		auto copied = new Field(_name, _description, _stringType, _length);

		// both copy _rawValue & _strValue
		copied.value = rawValue;

		// copy other properties
		copied.index      = index;
		copied.offset     = offset;
		copied.sign       = sign;
		copied.lowerBound = lowerBound;
		copied.upperBound = upperBound;

		return copied;
	}*/

	/// read property for name attribute
	@property string name() { return _name; }
	///
	unittest {
		auto field1 = new Field("FIELD1", "This is field #1", "A/N", 15);
		assert(field1.name == "FIELD1");
	}

/*
	/// write property for name attribute
	@property void name(string name) { _name = name; }
*/

	/// read property for description attribute
	@property string description() { return _description; }
	///
	unittest {
		auto field1 = new Field("FIELD1", "This is field #1", "A/N", 15);
		assert(field1.description == "This is field #1");
	}

	/// read property for element type
	@property FieldType fieldType() { return _fieldType; }
	///
	unittest {
		auto field1 = new Field("FIELD1", "This is field #1", "A/N", 15);
		assert(field1.fieldType.stringType == "A/N");
	}

	/// read property for field length
	@property ulong length() { return _length; }
	///
	unittest {
		auto field1 = new Field("FIELD1", "This is field #1", "A/N", 15);
		assert(field1.length == 15);
	}

	/// read property for cell length when creating ascii tables
	@property ulong cellLength() { return _cellLength; }
	///
	unittest {
		auto field1 = new Field("IDENTITY", "Name", "A/N", 30);
		field1.value = "John";
		assert(field1.cellLength == 30);
	}

	/// read/write property for field value
	@property string value() { return _strValue; }
	///
	unittest {
		auto field1 = new Field("IDENTITY", "Person's name", "A/N", 30);
		field1.value = "John Doe";
		assert(field1.value == "John Doe");
	}

	/// convert value to type T
	@property T value(T)() { return to!T(_strValue) * sign; }
	///
	unittest {
		auto field1 = new Field("AGE", "Person's age", "N", 3);
		field1.value = "50";
		assert(field1.value!int == 50);
	}

	/// set field value
	@property void value(string s)
	{
		_rawValue = s;
		_strValue = s.strip();
	}
	///
	unittest {
		auto field1 = new Field("AGE", "Person's age", "N", 3);
		field1.value = "50";
		assert(field1.value == "50");
	}

	/// read property for field raw value. Raw value is not stripped
	@property string rawValue() { return _rawValue; }
	///
	unittest {
		auto field1 = new Field("IDENTITY", "Person's name", "AN", 30);
		field1.value = "       John Doe      ";
		assert(field1.value == "John Doe");
		assert(field1.rawValue == "       John Doe      ");
	}

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
	 * return a string of the XML representation of Field
	 */
	string toXML() {
		return `<field seqnum="%d" position="%d" name="%s" description="%s" length="%d" type="%s"/>`
				.format(index+1, offset+1, name, description, length, fieldType);
	}

	/**
	 * test if field value matches condition using the operator.
	 */
	bool isFieldFilterMatched(in string op, in string rvalue)
	{
		return _fieldType.testFieldFilter(value, op, rvalue);
	}
	///
	unittest {
		auto field1 = new Field("AGE", "Person's age", "N", 3);
		field1.value = "50";
		assert(field1.isFieldFilterMatched("<","60"));
	}

	/// useful for unit tests
	bool opEquals(Tuple!(string,string,string,ulong) t) {
		return
			name == t[0] &&
			description == t[1] &&
			fieldType.stringType == t[2] &&
			length == t[3];
	}
	///
	unittest {
		auto field1 = new Field("AGE", "Person's age", "N", 3);
		assert(field1 == tuple("AGE", "Person's age", "N", 3UL));
	}

}
