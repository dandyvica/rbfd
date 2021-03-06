module rbf.field;
pragma(msg, "========> Compiling module ", __MODULE__);


import std.algorithm;
import std.ascii;
import std.conv;
import std.exception;
import std.regex;
import std.stdio;
import std.string;
import std.typecons;
import std.variant;

import rbf.errormsg;
import rbf.element;
import rbf.fieldtype;
import rbf.builders.xmlcore;

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
	size_t index;		     			/// index of the field within its parent record
	size_t offset;			    		/// offset of the field within its parent record from the first field
	size_t occurence;			    	/// index of the field within all the fields having the same name
	size_t lowerBound;				    /// when adding a field to a record, give
	size_t upperBound;		    		/// absolute position within the line read
	typeof(Field.name) alternateName;   /// when the field appers more than once, this builds unique 
                                        /// field name by adding its index
}

/******************************************************************************************************
 * This field class represents a field as found in record-based files
 */
class Field : Element!(string, size_t, ContextualInfo) 
{
private:

	FieldType _fieldType; 		      /// type of the field as defined in the XML file layout

	TVALUE _rawValue;                 /// pristine value
	TVALUE _strValue;		          /// store the string value of the field but stripped

	byte _valueSign = 1;			  /// sign of the scalar value if any

	Regex!char _fieldPattern;		  /// override field type pattern by this pattern
	string _charPattern;			  /// pattern as a string

    string _format;                   /// field format if specified

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
	this(in string name, in string description, FieldType type, in size_t length)
	{

		// just copy what is passed to constructor
		super(name, description, length);

        // by default, the alternate name is the field name. It might change if the same field name
        // is added to a record, and therefore depending on the context
        context.alternateName = name;

		// save field type
		_fieldType = type;

		// set pattern inherited from its type
        // pattern is here not a variable but a write property. Using a property is useful because
        // we might override the pattern set from the field type to that one read when set at field level
        pattern = type.meta.pattern;

        // save format if set in field type: this format is the printf-like format string specifier
        _format = type.meta.format;

        // as field length is known, we can set values length beforehand
        _rawValue.length = length;
        _strValue.length = length;
	}

	/**
 	 * create a new field object
	 *
	 * Params:
	 *	attr = associative array having keys "name", "description", "type", "length" with corresponding values
	 *
	 */
	this(string[string] attr)
	{
        // name & description keys should exists
        enforce("name" in attr, Message.MSG084);
        enforce("description" in attr, Message.MSG085);
        enforce("length" in attr, Message.MSG086);
        enforce("type" in attr, Message.MSG087);

        // just call regular ctor
        this(attr["name"], attr["description"], new FieldType(attr["type"], "string"), to!size_t(attr["length"]));
	}
	///
	/**
 	 * create a new field object from a CSV string
     * this is another ctor which might be useful
	 *
	 * Params:
	 * 	csvdata = string containing field data in CSV format
     *  delimiter = string used to split first argument
     *
     * Example:
     * auto field1 = new Field("FIELD1;Field description;N;decimal;15");
	 *
	 */
	this(in string csvdata, string delimiter=";")
	{
        // split string into individual atoms
		auto f = csvdata.split(delimiter);
		enforce(f.length == 5, Message.MSG010.format(f.length, 5));

		// create object calling the original ctor
		this(f[0], f[1], new FieldType(f[2],f[3]), to!size_t(f[4]));
	}

	/// read property for element type
	@property FieldType type() { return _fieldType; }

	/// write property for setting a new pattern for this field, hence
	/// overriding the field type one
	@property void pattern(in string s) { _charPattern = s; _fieldPattern = regex(s); }
	@property string pattern() { return _charPattern; };
	bool matchPattern() { return !matchAll(_strValue, _fieldPattern).empty; }

    /// property for field format
	@property void fieldFormat(in string s) { _format = s; }
	@property string fieldFormat() { return _format; };

	/// read/write property for field string value
	@property auto value() { return _strValue; }

    /// set a value by filling-in formatted data
    void setFormattedValue(char[] s)
    {
        //writef("before name=<%s:%d>, format=<%s>, value=<%s>", name, length, _format, s);
        _rawValue = _fieldType.meta.formatterCallback(s, length);
        //writefln(", rawValue=<%s>", rawValue);
    }

	/// convert value to type T
	@property T value(T)() { return to!T(_strValue) * sign; }

    // set the value of a field
	@property void value(in TVALUE s)
	{
        // raw value is exactly copied asis
		_rawValue = s;

		// convert if field type requests it
        // sometimes, the value read from field but must be first converted. This conversion
        // is declared in the <fieldtype> tag of the layout file
		if (type.meta.preConv) 
        {
			_strValue = type.meta.preConv(s.strip);
		}
		else
        {
			_strValue = s.strip;
        }
	}

	/// read property for field raw value. Raw value is not stripped
	@property auto rawValue() { return _rawValue; }

	/// read/write property for the sign field
	@property auto sign() { return _valueSign; }
	@property void sign(in byte new_sign) { _valueSign = new_sign; }

    /// build XML tag definition
    auto asXML()
    {
        XmlAttribute[] attributes;

        // build attribute elements for mandatory attributes of <field> tag
        attributes ~= XmlAttribute("name", name);
        attributes ~= XmlAttribute("description", description);
        attributes ~= XmlAttribute("length", to!string(length));
        attributes ~= XmlAttribute("type", type.meta.name);

        // build XML
        return buildXmlTag("field", attributes);
    }

	/**
	 * return a string of Field attributes
	 */
	override string toString() 
    {
		with(context) 
        {
			return(Message.MSG003.format(name, description, length, type, lowerBound, upperBound, rawValue, value, offset, index));
		}
	}
    auto contextualInfo()
    {
        return "name=<%s>, alternateName=<%s>, index=<%d>, offset=<%d>".format(name, context.alternateName, context.index+1, context.offset+1);
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

    /// convert string value to type T
	T opCast(T)() { return to!T(_strValue); }

    /// get rid of ascci char having value < 32
    auto sanitize(in string s) pure const
    { 
        static immutable controlChars = x"000102030405060708090A0B0C0D0E0F10111213141516171819";
        return s.removechars(controlChars);
    }

}
///
unittest 
{
    writefln("\n========> testing %s", __FILE__);

    auto ft = new FieldType("N","decimal");
    auto f1 = new Field("AGE", "Person's age", ft, 13);

    f1.value = "   123A   ";
    //assert(!f1.matchPattern);
    f1.value = "   12   ";
    assert(f1.matchPattern);
    f1.value = "   123   ";
    assert(f1.matchPattern);

    auto field1 = new Field("FIELD1", "Field description", new FieldType("N","decimal"), 15);
    assert(field1 == tuple("FIELD1", "Field description", "N", 15UL));

    field1 = new Field("IDENTITY", "Person's name", new FieldType("S","string"), 30);
    field1.value = "  John Doe   ";
    assert(field1.value == "John Doe");

    field1 = new Field("IDENTITY", "Person's name", new FieldType("CHAR","string"), 30);
    assert(field1.asXML == `<field name="IDENTITY" description="Person's name" length="30" type="CHAR"/>`);

    field1 = new Field("AGE", "Person's age", new FieldType("INT","integer"), 3);
    assert(field1 == tuple("AGE", "Person's age", "INT", 3UL));

    field1 = new Field("AGE", "Person's age", new FieldType("I","integer"), 3);
    field1.value = " 50";
    assert(to!int(field1) == 50);

    field1 = new Field("AGE", "Person's age", new FieldType("I","integer"), 3);
    field1.value = "50";
    assert(field1.value == "50");

    field1 = new Field("IDENTITY", "Person's name", new FieldType("CHAR","string"), 30);
    field1.value = "       John Doe      ";
    assert(field1.value == "John Doe");
    assert(field1.rawValue == "       John Doe      ");

    field1 = new Field("AGE", "Person's age", new FieldType("N","decimal"), 3);
    field1.value = "50";
    assert(field1.value!int == 50);

    field1 = new Field("FIELD1;Field description;N;decimal;15");
    assertThrown(new Field("FIELD1;Field description;N;decimal"));

    writefln("********> end test %s\n", __FILE__);
}
