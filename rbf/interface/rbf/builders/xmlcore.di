// D import file generated from 'source/rbf/builders/xmlcore.d'
module rbf.builders.xmlcore;
pragma (msg, "========> Compiling module ", "rbf.builders.xmlcore");
import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.exception;
struct Sanitizer
{
	bool strip;
	bool capitalize;
	bool uppercase;
	string[][] replaceRegex;
	string sanitize(string stringToSanitize);
}
struct XmlAttribute
{
	string name;
	string value;
}
auto buildXmlTag(string tagName, XmlAttribute[] attributes, bool emptyTag = true)
{
	if (attributes == [])
		return "</%s>".format(tagName);
	string[] builtXmlAttributes;
	foreach (attr; attributes)
	{
		builtXmlAttributes ~= "%s=\"%s\"".format(attr.name, attr.value);
	}
	auto tag = "<%s %s".format(tagName, builtXmlAttributes.join(" "));
	return emptyTag ? tag ~ "/>" : tag ~ ">";
}
