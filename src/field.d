module rbf.field;

import std.stdio;
import std.conv;
import std.string;
import std.regex;

//import util.common;
/***********************************
 * Used to define a finite list of
 * possible field types 
 */
enum FieldType { 
	NUMERICAL,  
	ALPHABETICAL,
	ALPHANUMERICAL
}

/***********************************
 *This field class represents a field as found 
 * in record-based files
 */
class Field {
private:
	
	FieldType _field_type;  		/// type of the element. Ex: A/N
	string _name;					/// name of the element. Ex: TDNR	
	immutable string _description;	/// description of the element. Ex: Ticket/Document Identification Record	
	immutable ulong _length;		/// length (in bytes) of the field
	immutable string _type;			/// type as passed to the ctor 
	string _raw_value;              /// pristine value
	string _str_value;				/// when set, store the value of the field
	
	ulong _index;
	ulong _offset;

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
	 * Examples: auto tdnr = new Field('FIELD1', 'Field description', 'A/N', 15);
	 */
	this(in string name, in string description, in string type, in ulong length) 
	// verify pre-conditions
	{
		// check arguments
		enforce(length > 0, "field length should be > 0");
		enforce(name != "", "field name should not be empty!");
		
		// just copy what is passed to constructor
		_name = name;
		_description = description;
		_length = length;
		
		// value is empty by default
		_str_value = "";
		_raw_value = "";
		
		// set type according to what is passed
		_type = type;
		switch (type)
		{
			case "N":
			case "I":
			case "D":
				_field_type = FieldType.NUMERICAL;
				break;
			case "A":
				_field_type = FieldType.ALPHABETICAL;
				break;
			case "AN":
			case "A/N":
				_field_type = FieldType.ALPHANUMERICAL;
				break;
			default:
				throw new Exception("unknown field type %s".format(type));				
		}

	}

	// copy a field with all its data
	Field dup() {
			auto copied = new Field(_name, _description, _type, _length);
			
			// both copy _raw_value & _str_value
			copied.value = rawvalue;
			
			return copied;
	}

	/**
	 * properties
	 */	
	@property string name() { return _name; } 				 // read property for element name
	@property void name(string name) { _name = name; } 		 // write property for element name. Used to rename an element
	
	@property string description() { return _description; } // read property for element description
	
	@property FieldType type() { return _field_type; } 				// read property for element type
	
	@property ulong length() { return _length; } 	 // read property for field length
	
	@property string value() { return _str_value; }  // read property for field value
	@property void value(string s) // write property	
    {
    	_raw_value = s;
		_str_value = s.strip();
	}
    
    @property string rawvalue() { return _raw_value; }
    
    @property ulong index() { return _index; }
    @property void index(ulong new_index) { _index = new_index; }
    
    @property ulong offset() { return _offset; }
    @property void offset(ulong new_offset) { _offset = new_offset; }
    	
	
	/**
	 * print out Field properties
	 */
	override string toString() {
		return("name=<%s>, description=<%s>, length=<%u>, type=<%s>, value=<%s>, offset=<%s>, index=<%s>"
			             .format(name, description, length, type, value, offset, index));
	}

}



import std.exception;
unittest {
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
	

