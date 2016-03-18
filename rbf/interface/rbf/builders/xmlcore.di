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
	bool capitalize;
	bool uppercase;
	string[] replaceRegex;
}
struct XmlAttribute
{
	string name;
	string value;
	Sanitizer nameSanitizer;
	Sanitizer valueSanitizer;
	void sanitizeName();
	void sanitizeValue();
	private string _sanitize(string stringToSanitize, Sanitizer options);
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
