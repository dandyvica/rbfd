module rbf.builders.xmlcore;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.exception;

// list all possible options when sanitizing data
struct Sanitizer
{
    bool capitalize;            /// capitilize string 
    bool uppercase;             /// convert to uppercase
    string[] replaceRegex;      /// replace matching the regex
}

// defined a structure for attributes
struct XmlAttribute
{
    // core data
    string name;
    string value;

    // sanitizing options
    Sanitizer nameSanitizer;
    Sanitizer valueSanitizer;

    // sanitize methods
    void sanitizeName()
    {
        name = _sanitize(name, nameSanitizer);
    }

    // sanitize methods
    void sanitizeValue()
    {
        value = _sanitize(value, valueSanitizer);
    }

private:
    string _sanitize(string stringToSanitize, Sanitizer options)
    {
        // copy input string
        auto s = stringToSanitize.strip;

        // sanitize data according to options
        with(options)
        {
            if (capitalize) s = s.capitalize;
            if (uppercase) s = s.toUpper;
        }

        // return sanitized string
        return s;
    }
}


auto buildXmlTag(string tagName, XmlAttribute[] attributes, bool emptyTag=true)
{
    // if we pass no attributes, return ending tag
    if (attributes == []) return "</%s>".format(tagName);

    // attribute array built from argument
    string[] builtXmlAttributes;

    // build list of attributes
    foreach (attr; attributes)
    {
        builtXmlAttributes ~= `%s="%s"`.format(attr.name, attr.value);
    }

    // build tag
    auto tag = "<%s %s".format(tagName, builtXmlAttributes.join(" "));

    // empty tag?
    return (emptyTag) ? tag ~ "/>" : tag ~ ">";
}

///
unittest
{
    auto s = buildXmlTag("field", [XmlAttribute("name", "FIELD1"), XmlAttribute("description", "Field1 description")]);
	assert(s == `<field name="FIELD1" description="Field1 description"/>`);
    s = buildXmlTag("field", [XmlAttribute("name", "FIELD1"), XmlAttribute("description", "Field1 description")], false);
	assert(s == `<field name="FIELD1" description="Field1 description">`);
}
