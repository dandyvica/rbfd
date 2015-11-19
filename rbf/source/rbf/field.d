module rbf.field;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.typecons;
import std.exception;
import std.typecons;
import std.variant;

import rbf.errormsg;
import rbf.element;
import rbf.fieldtype;

/***********************************
 * type used to hold values read from file
 */
//alias TVALUE = char[];
alias TVALUE = string;
pragma(msg, "========> TVALUE = ", TVALUE.stringof);

/***********************************
 * These information are based on the context: a field within a record
 */
struct ContextualInfo 
{
	ulong index;					/// index of the field within its parent record
	ulong offset;					/// offset of the field within its parent record from the first field
	ulong occurence;				/// index of the field within all the fields having the same name
	ulong lowerBound;				/// when adding a field to a record, give
	ulong upperBound;				/// absolute position within the line read
	typeof(Field.name) alternateName;/// when the field appers more than once, this builds unique field name by adding its index
}

/******************************************************************************************************
 * This field class represents a field as found in record-based files
 */
class Field : Element!(string, ulong, ContextualInfo) 
{
private:

	FieldType _fieldType; 		      /// type of the field as defined in the XML layout

	TVALUE _rawValue;                 /// pristine value
	TVALUE _strValue;		          /// store the string value of the field

	byte _valueSign = 1;			  /// sign of the scalar value if any

	Regex!char _fieldPattern;		  /// override field type pattern by this
	string _charPattern;			  /// pattern as a string

public:
	/**
 	 * create a new field object
	 *
	 * Params:
	 * 	name = name of the field
	 *  description = a generally long description of the field
	 *  ftype = FieldType object
	 *  length = length in bytes of the field. Should be >0
	 *
	 */
	this(in string name, in string description, FieldType type, in ulong length)
	// verify pre-conditions
	{

		// just copy what is passed to constructor
		super(name, description, length);
        context.alternateName = name;

		// save field type
		_fieldType = type;

		// set pattern from its type
		_charPattern  = type.meta.pattern;
		_fieldPattern = regex(_charPattern);

        //_rawValue = new char[length];
        //_strValue = new char[length];
	}
	///
	unittest {
		auto field1 = new Field("FIELD1", "Field description", new FieldType("N","decimal"), 15);
	}

	/**
 	 * create a new field object from a CSV string
	 *
	 * Params:
	 * 	csvdata = string containing field data in CSV format
     *
     * Example:
     * auto field1 = new Field("FIELD1;Field description;N;decimal;15");
	 *
	 */
	this(in string csvdata)
	{
		auto f = csvdata.split(";");
		enforce(f.length == 5, MSG010.format(f.length, 5));
		// create object
		this(f[0], f[1], new FieldType(f[2],f[3]), to!ulong(f[4]));
	}
	///
	unittest 
    {
		auto field1 = new Field("FIELD1;Field description;N;decimal;15");
		assertThrown(new Field("FIELD1;Field description;N;decimal"));
	}

	/// read property for element type
	@property FieldType type() { return _fieldType; }

	/// write property for setting a new pattern for this field, hence
	/// overriding the field type one
	@property void pattern(in string s) { _charPattern = s; _fieldPattern = regex(s); }
	bool matchPattern() { return !matchAll(_rawValue.strip, _fieldPattern).empty; }

	/// read/write property for field value
	@property auto value() { return _strValue; }
	///
	unittest 
    {
		auto field1 = new Field("IDENTITY", "Person's name", new FieldType("S","string"), 30);
		field1.value = "  John Doe   ";
		assert(field1.value == "John Doe");
	}

	/// convert value to type T
	@property T value(T)() { return to!T(_strValue) * sign; }
	///
	unittest 
    {
		auto field1 = new Field("AGE", "Person's age", new FieldType("N","decimal"), 3);
		field1.value = "50";
		assert(field1.value!int == 50);
	}

	@property void value(TVALUE s)
	{
		_rawValue = s;

		// convert if field type requests it
		if (type.meta.preConv) 
        {
			_strValue = type.meta.preConv(s.strip);
		}
		else
			_strValue = s.strip;
	}
	///
	unittest 
    {
		auto field1 = new Field("AGE", "Person's age", new FieldType("I","integer"), 3);
		field1.value = "50";
		assert(field1.value == "50");
	}

	/// read property for field raw value. Raw value is not stripped
	@property auto rawValue() { return _rawValue; }
	///
	unittest 
    {
		auto field1 = new Field("IDENTITY", "Person's name", new FieldType("CHAR","string"), 30);
		field1.value = "       John Doe      ";
		assert(field1.value == "John Doe");
		assert(field1.rawValue == "       John Doe      ");
	}

	/// read/write property for the sign field
	@property auto sign() { return _valueSign; }
	@property void sign(in byte new_sign) { _valueSign = new_sign; }

	/**
	 * return a string of Field attributes
	 */
	override string toString() 
    {
		with(context) 
        {
			return(MSG003.format(name, description, length, type, lowerBound, upperBound, rawValue, value, offset, index));
		}
	}

	/// useful for unit tests
	bool opEquals(Tuple!(string,string,string,ulong) t)
    {
		return
			name           == t[0] &&
			description    == t[1] &&
			type.meta.name == t[2] &&
			length         == t[3];
	}
	///
	unittest 
    {
		auto field1 = new Field("AGE", "Person's age", new FieldType("INT","integer"), 3);
		assert(field1 == tuple("AGE", "Person's age", "INT", 3UL));
	}

	T opCast(T)() { return to!T(_strValue); }
	///
	unittest 
    {
		auto field1 = new Field("AGE", "Person's age", new FieldType("I","integer"), 3);
		field1.value = " 50";
		assert(to!int(field1) == 50);

		// field1 = new Field("AGE", "Person's age", new FieldType("O","overpunchedInteger"), 10);
		// field1.value = " 5{}";
		// assert(to!int(field1) == 500);
	}

}
///
unittest 
{

		writeln("========> testing ", __FILE__);

		auto ft = new FieldType("N","decimal");
		ft.meta.pattern = r"^\d{1,2}$";
		auto f1 = new Field("AGE", "Person's age", ft, 13);

		f1.value = "   123   ";
		assert(!f1.matchPattern);
		f1.value = "   12   ";
		assert(f1.matchPattern);
		// set new pattern independantly from field type pattern
		// and now it works
		f1.pattern = r"^\d{1,3}$";
		f1.value = "   123   ";
		assert(f1.matchPattern);

		//assert(to!int(f1) == 123);

		//
		// auto f2 = new Field("AGE", "Person's age", new rbfOverpunchedInteger(r"^[\d+A-R{}]$"), 13);
		// f2.value = "   1A{}   ";
		// assert(to!int(f2) == 1100);
		// assert(f2.matchPattern);
		//
		//
		// assert(f1.field)


}
