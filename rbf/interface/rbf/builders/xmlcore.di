// D import file generated from 'source/rbf/builders/xmlcore.d'
module rbf.builders.xmlcore;
pragma (msg, "========> Compiling module ", "rbf.builders.xmlcore");
import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
import std.typecons;
import std.exception;
import std.typecons;
import std.variant;
struct Attribute
{
	string name;
	string value;
}
auto buildXmlTag(string tagName, Attribute[] attributes, bool emptyTag = true)
{
	if (attributes == [])
		return "</%s>".format(tagName);
	string[] builtAttributes;
	foreach (attr; attributes)
	{
		builtAttributes ~= "%s=\"%s\"".format(attr.name, attr.value);
	}
	auto tag = "<%s %s".format(tagName, builtAttributes.join(" "));
	return emptyTag ? tag ~ "/>" : tag ~ ">";
}
