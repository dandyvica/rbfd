module rbf.field;

import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.variant;

//import util.common;
/***********************************
 * Provides the Field class to manage text fields within
* a record-based file
 */
enum FieldType {
	FLOAT,
	INTEGER,
	DATE,
	ALPHABETICAL,
	ALPHANUMERICAL
}

/***********************************
 *This field class represents a field as found
 * in record-based files
 */
class Field {
private:

	FieldType _fieldType; 		/// enum type of the field
	string _name;					/// name of the element. Ex                 : TDNR
	immutable string _description;	/// description of the element. Ex: Ticket/Document Identification Record
	immutable ulong _length;		/// length (in bytes) of the field
	immutable string _type;			/// type as passed to the ctor
	string _rawValue; /// pristine value
	string _strValue;				/// when set, store the value of the field

	ulong _index;					/// index of the field within its parent record
	ulong _offset;					/// index of the field within its parent record from the first field
	ulong _lowerBound;
	ulong _upperBound;

	float _float_value;				/// hold values when converted
	uint _int_value;

	short _value_sign = 1;			/// positive value for the moment

	immutable ulong _cellLength; ///

	Variant _convertedValue;


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
		switch (type)
		{
			case "N":
				_fieldType = FieldType.FLOAT;
				break;
			case "I":
				_fieldType = FieldType.INTEGER;
				break;
			case "D":
				_fieldType = FieldType.DATE;
				break;
			case "A":
				_fieldType = FieldType.ALPHABETICAL;
				break;
			case "AN":
			case "A/N":
				_fieldType = FieldType.ALPHANUMERICAL;
				break;
			default:
				throw new Exception("unknown field type %s".format(type));
		}

	}

	// copy a field with all its data
	Field dup() {
		auto copied = new Field(_name, _description, _type, _length);

		// both copy _rawValue & _strValue
		copied.value = rawvalue;

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
	@property FieldType type() { return _fieldType; }
	@property string declaredType() { return _type; }

	/// read property for field length
	@property ulong length() { return _length; }

	/// read property for cell length when creating ascii tables
	@property ulong cell_length() { return _cellLength; }

	/// read/write property for field value
	@property string value() { return _strValue; }
	@property void value(string s)
	{
		_rawValue = s;
		_strValue = s.strip();
	}

	/// read property for field raw value. Raw value is not stripped
	@property string rawvalue() { return _rawValue; }

	/// read/write property for the field index
	@property ulong index() { return _index; }
	@property void index(ulong new_index) { _index = new_index; }

	/// read/write property for the field offset
	@property ulong offset() { return _offset; }
	@property void offset(ulong new_offset) { _offset = new_offset; }

	/// read/write property for the sign field
	@property short sign() { return _value_sign; }
	@property void sign(short new_sign) { _value_sign = new_sign; }

	/// read/write property lower/upper bounds
	@property ulong lowerBound() { return _lowerBound; }
	@property ulong upperBound() { return _upperBound; }
	@property void lowerBound(ulong new_bound) { _lowerBound = new_bound; }
	@property void upperBound(ulong new_bound) { _upperBound = new_bound; }

	/// convert field value to scalar value (float or integer)
	void convert() {
		if (_fieldType == FieldType.FLOAT) {
			_float_value = to!float(_strValue) * _value_sign;
		} else if (_fieldType == FieldType.INTEGER || _fieldType == FieldType.DATE) {
			_float_value = to!float(_strValue) * _value_sign;
			_int_value = to!uint(_strValue);
		}
	}

	/**
	 * return a string of Field attributes
	 */
	override string toString() {
		return("name=<%s>, description=<%s>, length=<%u>, type=<%s>, lower/upperBound=<%u:%u>, value=<%s>, offset=<%s>, index=<%s>"
			             .format(name, description, length, type, lowerBound, upperBound, value, offset, index));
	}

	/**
	 * test if field value matches condition using the operator.
	 *
	 *  Example: FIELD1 = TEST
	 */
	bool isFilterMatched(in string operator, in string scalar)
	{
		bool condition;
		//writefln("Field.matchCondition: <%s>, <%s>", operator, scalar);

		// otherwise, get field value and compare it to scalar values
		switch (operator)
		{
			case "=":
			case "==":
				mixin(testFilter("=="));
				break;

			case "!=":
				mixin(testFilter("!="));
				break;

			case "<":
				mixin(testFilter("<"));
				break;

			case ">":
				mixin(testFilter(">"));
				break;

			case "~":
				if (_fieldType != FieldType.ALPHABETICAL &&
						_fieldType != FieldType.ALPHANUMERICAL)
					throw new Exception("operator ~ not supported for numeric fields, field name = <%s>".format(name));

				condition = !match(value, regex(scalar)).empty;
				break;

			case "!~":
				if (_fieldType != FieldType.ALPHABETICAL &&
					_fieldType != FieldType.ALPHANUMERICAL)
					throw new Exception("operator !~ not supported for numeric fields, field name = <%s>".format(name));

				condition = match(value, regex(scalar)).empty;
				break;

			default:
				throw new Exception("operator %s not supported".format(operator));
		}
		return condition;
	}

	/**
	 * mixin macro for syntactic sugar
	 */
	static string testFilter(in string operator)
	{
		return (
			"if (_fieldType == FieldType.ALPHABETICAL ||
				_fieldType == FieldType.ALPHANUMERICAL)
					{ condition = (value " ~ operator ~ " scalar); }
			else { condition = to!float(value) " ~ operator ~ " to!float(scalar); }"
		);
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
