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
 * These information are based on the context: a field within a record
 */
struct ContextualInfo {
	ulong index;					          /// index of the field within its parent record
	ulong offset;					          /// offset of the field within its parent record from the first field
	ulong occurence;								/// index of the field within all the fields having the same name
	ulong lowerBound;				        /// when adding a field to a record, give
	ulong upperBound;								/// absolute position within the line read
	string alternateName;						///
}

/***********************************
 *This field class represents a field as found
 * in record-based files
 */
class Field : Element!(string, ulong, ContextualInfo) {
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
	string _charPattern;							/// pattern as a string

	// Variant _value;										/// the final value that is depending on the fieldtype
	// Algebraic!(int, string, float) _value2;

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

		// set pattern from its type
		_charPattern  = type.meta.pattern;
		_fieldPattern = regex(_charPattern);
	}
	///
	unittest {
		auto field1 = new Field("FIELD1", "Field description", new FieldType("N","decimal"), 15);
	}

	/// read property for element type
	@property FieldType type() { return _fieldType; }

	/// write property for setting a new pattern for this field, hence
	/// overriding the field type one
	@property void pattern(string s) { _charPattern = s; _fieldPattern = regex(s); }
	bool matchPattern() { return !matchAll(_rawValue.strip, _fieldPattern).empty; }

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

	@property void value(in string s)
	{
		_rawValue = s;
		auto _strippedValue = s.strip;

		// convert if field type requests it
		if (type.meta.preConv) {
			_strValue = type.meta.preConv(s.strip);
		}
		else
			_strValue = s.strip;
		//_value = T.conv(_strValue);

		// if (type.fieldType == AtomicType.integer) {
		// 	writefln("_strValue == <%s>", _strValue);
		// 	_value2 = to!int(_strValue);
		// 	writefln("_value2 == <%s>", _value2);
		// }

		// do we need to chek value?
		if (type.meta.checkPattern) {
			// writefln("field=%s, type=%s, value=<%s>, checkPattern=%s, pattern=%s, match=%s, empty?=%s",
			// 	name, type.name, _strippedValue, type.extra.checkPattern, type.extra.pattern, matchPattern,
			// 		matchAll(_rawValue.strip, regex(type.extra.pattern)).empty);
			if (_strippedValue!= "" && !matchPattern) {
				stderr.writefln(MSG002, this, _charPattern);
			}
		}

	}
	///
	unittest {
		auto field1 = new Field("AGE", "Person's age", new FieldType("I","integer"), 3);
		field1.value = "50";
		assert(field1.value == "50");

		// field1 = new Field("AGE", "Person's age", new FieldType("N","overpunchedInteger"), 10);
		// field1.value = "  5{}";
		// assert(field1.value == "500");
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

	// /// read/write property for the field index
	// @property ulong index() { return _index; }
	// @property void index(ulong new_index) { _index = new_index; }
	//
	// /// read/write property for the field offset
	// @property ulong offset() { return _offset; }
	// @property void offset(ulong new_offset) { _offset = new_offset; }
	//
	// /// read/write property lower/upper bounds
	// @property ulong lowerBound() { return _lowerBound; }
	// @property ulong upperBound() { return _upperBound; }
	// @property void lowerBound(ulong new_bound) { _lowerBound = new_bound; }
	// @property void upperBound(ulong new_bound) { _upperBound = new_bound; }

	/// read/write property for the sign field
	@property byte sign() { return _valueSign; }
	@property void sign(byte new_sign) { _valueSign = new_sign; }

	/**
	 * return a string of Field attributes
	 */
	override string toString() {
		with(context) {
			return(MSG003.format(name, description, length, type, lowerBound, upperBound, rawValue, value, offset, index));
		}
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
			name           == t[0] &&
			description    == t[1] &&
			type.meta.name == t[2] &&
			length         == t[3];
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

		// field1 = new Field("AGE", "Person's age", new FieldType("O","overpunchedInteger"), 10);
		// field1.value = " 5{}";
		// assert(to!int(field1) == 500);
	}

}
///
unittest {

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
