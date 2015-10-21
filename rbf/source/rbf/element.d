module rbf.element;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.string;


/***********************************
 * This is the core data for representing field data in record-based files
 */
class Element(T,U) {
private:

	T _name;					            		/// name of the element
	immutable T _description;	  			/// description of the element
	immutable U _length;		      		/// length (in bytes) of the field
	immutable U _cellLength1; 				/// used ot correctly print ascii tables
	immutable U _cellLength2; 				/// used ot correctly print ascii tables

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
	this(in T name, in T description, in U length)
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
		_cellLength1 = max(_length, _name.length);
		_cellLength2 = max(_length, _description.length, _name.length);
	}
	///
	unittest {
		assertThrown(new Element!(string, ulong)("","First field", 5));
		assertThrown(new Element!(string, ulong)("FIELD1","First field", 5));
		assertThrown(new Element!(string, ulong)("FIELD1","First field", 0));
		auto e1 = new Element!(string, ulong)("FIELD1", "Field description", 15);
	}

	// copy an element with all its data
	Element dup() {
		auto copied = new Element(T,U)(_name, _description, _length);
		return copied;
	}

	/// read property for name attribute
	@property T name() { return _name; }
	///
	unittest {
		auto element1 = new Element!(string, ulong)("FIELD1", "This is element #1", 15);
		assert(element1.name == "FIELD1");
	}

	/// read property for description attribute
	@property T description() { return _description; }
	///
	unittest {
		auto element1 = new Element!(string, ulong)("FIELD1", "This is element #1", 15);
		assert(element1.description == "This is field #1");
	}

	/// read property for field length
	@property U length() { return _length; }
	///
	unittest {
		auto element1 = new Element!(string, ulong)("FIELD1", "This is field #1", 15);
		assert(element1.length == 15);
	}

	/// read property for cell length when creating ascii tables
	@property U cellLength1() { return _cellLength1; }
	@property U cellLength2() { return _cellLength2; }
	///
	unittest {
		auto element1 = new Element!(string, ulong)("IDENTITY", "Name", 30);
		element1.value = "John";
		assert(element1.cellLength1 == 30);
		assert(element1.cellLength2 == 30);
	}

	/**
	 * return a string of Field attributes
	 */
	override string toString() {
		return("name=<%s>, description=<%s>, length=<%u>".format(name, description, length));
	}

}





/////////////////////////////

class FType(T) {
	this(string pattern, string format)
	{

	}
}

class F(T): Element!(string,ulong) {

		string _strValue;
		T _typedValue;

}
