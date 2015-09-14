// D import file generated from 'source/fieldtype.d'
module rbf.fieldtype;
import std.stdio;
import std.conv;
import std.string;
import std.regex;
import std.algorithm;
enum AtomicType 
{
	FLOAT,
	INTEGER,
	DATE,
	ALPHABETICAL,
	ALPHANUMERICAL,
}
class FieldType
{
	private 
	{
		string _declaredType;
		AtomicType _atom;
		Regex!char re;
		public 
		{
			this(in string type);
			@property AtomicType type();
			@property void pattern(string p);
		}
	}
}
import std.exception;
