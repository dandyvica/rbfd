// D import file generated from 'source/filter.d'
module rbf.filter;
import std.stdio;
import std.file;
import std.string;
import std.algorithm;
import std.regex;
import std.exception;
struct Clause
{
	string fieldName;
	string operator;
	string scalar;
}
class Filter
{
	private 
	{
		Clause[] _fitlerClause;
		public 
		{
			this(string filterFile);
			int opApply(int delegate(ref Clause) dg);
			override string toString();
		}
	}
}
