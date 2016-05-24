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
    bool strip;                 /// strip string
    bool capitalize;            /// capitilize string 
    bool uppercase;             /// convert to uppercase
    string[][] replaceRegex;      /// replace matching the regex

    string sanitize(string stringToSanitize)
    {
        // copy input string
        auto s = stringToSanitize.strip;

        // sanitize data according to options
        if (strip) s = s.strip;
        if (capitalize) s = s.capitalize;
        if (uppercase) s = s.toUpper;

        // replace chars
        foreach (r; replaceRegex)
        {
            // replace string
            s = replaceAll(s, regex(r[0]), r[1]);
        }

        // return sanitized string
        return s;
    }
}

// defined a structure for attributes
struct XmlAttribute
{
    // core data
    string name;
    string value;
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
