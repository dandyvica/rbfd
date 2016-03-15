module rbf.builders.xmlcore;
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

// defined a structure for attributes
struct Attribute
{
    string name;
    string value;
}


auto buildXmlTag(string tagName, Attribute[] attributes, bool emptyTag=true)
{
    // if we pass no attributes, return ending tag
    if (attributes == []) return "</%s>".format(tagName);

    // attribute array built from argument
    string[] builtAttributes;

    // build list of attributes
    foreach (attr; attributes)
    {
        builtAttributes ~= `%s="%s"`.format(attr.name, attr.value);
    }

    // build tag
    auto tag = "<%s %s".format(tagName, builtAttributes.join(" "));

    // empty tag?
    return (emptyTag) ? tag ~ "/>" : tag ~ ">";
}

///
unittest
{
    auto s = buildXmlTag("field", [Attribute("name", "FIELD1"), Attribute("description", "Field1 description")]);
	assert(s == `<field name="FIELD1" description="Field1 description"/>`);
    s = buildXmlTag("field", [Attribute("name", "FIELD1"), Attribute("description", "Field1 description")], false);
	assert(s == `<field name="FIELD1" description="Field1 description">`);
}
