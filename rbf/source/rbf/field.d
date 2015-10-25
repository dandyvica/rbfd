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

import rbf.element;
import rbf.fieldtype;

/***********************************
 *This field class represents a field as found
 * in record-based files
 */
class Field : Element!(string, ulong) {
private:

	FieldType _fieldType; 		        /// type of the field

	string _rawValue;                 /// pristine value
	string _strValue;				          /// store the string value of the field

	ulong _index;					            /// index of the field within its parent record
	ulong _offset;					          /// offset of the field within its parent record from the first field

	ulong _lowerBound;				        /// when adding a field to a record, give
	ulong _upperBound;								/// absolute position within the line read

	byte _valueSign = 1;			        /// sign of the scalar value if any

	Regex!char _fieldPattern;					/// override filed type pattern by this

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
	this(in string name, in string description, FieldType type, in ulong length)
	// verify pre-conditions
	{

		// just copy what is passed to constructor
		super(name, description, length);

		// save field type
		_fieldType = type;

		// copy pattern from its type
		_fieldPattern = regex(type.pattern);
	}
	///
	unittest {
		auto field1 = new Field("FIELD1", "Field description", new FieldType("N","decimal"), 15);
	}

	/// read property for element type
	@property FieldType type() { return _fieldType; }

	/// write property for setting a new pattern for this field, hence
	/// overriding the field type one
	@property void pattern(string s) { _fieldPattern = regex(s); }
	bool matchPattern() { return !matchFirst(_rawValue.strip, _fieldPattern).empty; }

	/// read/write property for field value
	@property string value() { return _strValue; }
	///
	unittest {
		auto field1 = new Field("IDENTITY", "Person's name", new FieldType("S","string"), 30);
		field1.value = "  John Doe   ";
		assert(field1.value == "John Doe");
	}

	/// convert value to type T
	@property T value(T)() { return to!T(_strValue) * sign; }
	///
	unittest {
		auto field1 = new Field("AGE", "Person's age", new FieldType("N","decimal"), 3);
		field1.value = "50";
		assert(field1.value!int == 50);
	}

	// /// copy field value when read from a file
	// @property void value(string s)
	// {
	// 	_rawValue = s;
	// 	_strValue = s.strip();
	// }
	// ///
	// unittest {
	// 	auto field1 = new Field("AGE", "Person's age", new FieldType!float, 3);
	// 	field1.value = "50";
	// 	assert(field1.value == "50");
	// }

	@property void value(string s)
	{
		_rawValue = s;

		// convert if field type requests it
		if (type.preConv) {
			_strValue = type.preConv(s.strip);
		}
		else
			_strValue = s.strip;
		//_value = T.conv(_strValue);
	}
	///
	unittest {
		auto field1 = new Field("AGE", "Person's age", new FieldType("I","integer"), 3);
		field1.value = "50";
		assert(field1.value == "50");

		field1 = new Field("AGE", "Person's age", new FieldType("N","overpunchedInteger"), 10);
		field1.value = "  5{}";
		assert(field1.value == "500");
	}

	/// set field value
	// @property void setValue(string s)
	// {
	// 	// when field is string, we need to left justify with blanks
	// 	if (_fieldType.type == AtomicType.string) {
	// 		_strValue = s.strip();
	// 		_rawValue = _strValue.leftJustify(_length);
	// 	}
	// 	else if (_fieldType.type == AtomicType.decimal) {
	// 		_strValue = s.strip();
	// 		_rawValue = _strValue.rightJustify(_length,'0');
	// 	}
	// }
	///
	// unittest {
	// 	auto field1 = new Field("FIELD1", "Desc1", new FieldType!string, 10);
	// 	field1.setValue("AA");
	// 	assert(field1.rawValue == "AA        ");
	// 	field1 = new Field("FIELD1", "Desc1", "N", 10);
	// 	field1.setValue("12.34");
	// 	assert(field1.rawValue == "0000012.34");
	// }



	/// read property for field raw value. Raw value is not stripped
	@property string rawValue() { return _rawValue; }
	///
	unittest {
		auto field1 = new Field("IDENTITY", "Person's name", new FieldType("CHAR","string"), 30);
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
			             .format(name, description, length, type, lowerBound, upperBound, value, offset, index));
	}

	/**
	 * test if field value matches condition using the operator.
	 */
	// bool isFieldFilterMatched(in string op, in string rvalue)
	// {
	// 	return _fieldType.testFieldFilter(value, op, rvalue);
	// }
	// ///
	// unittest {
	// 	auto field1 = new Field("AGE", "Person's age", "N", 3);
	// 	field1.value = "50";
	// 	assert(field1.isFieldFilterMatched("<","60"));
	// }

	/// useful for unit tests
	bool opEquals(Tuple!(string,string,string,ulong) t) {
		return
			name == t[0] &&
			description == t[1] &&
			type.name == t[2] &&
			length == t[3];
	}
	///
	unittest {
		auto field1 = new Field("AGE", "Person's age", new FieldType("INT","integer"), 3);
		assert(field1 == tuple("AGE", "Person's age", "INT", 3UL));
	}

	T opCast(T)() { return to!T(_strValue); }
	///
	unittest {
		auto field1 = new Field("AGE", "Person's age", new FieldType("I","integer"), 3);
		field1.value = " 50";
		assert(to!int(field1) == 50);

		field1 = new Field("AGE", "Person's age", new FieldType("O","overpunchedInteger"), 10);
		field1.value = " 5{}";
		assert(to!int(field1) == 500);
	}

}
///
unittest {

		writeln("========> testing ", __FILE__);

		auto f1 = new Field("AGE", "Person's age", new FieldType("N","decimal", r"^\d{1,2}$"), 13);

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
