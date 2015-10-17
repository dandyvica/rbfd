// D import file generated from 'source\rbf\recordfilter.d'
module rbf.recordfilter;
import std.stdio;
import std.file;
import std.string;
import std.algorithm;
import std.regex;
import std.exception;
struct RecordClause
{
	string fieldName;
	string operator;
	string scalar;
}
class RecordFilter
{
	private 
	{
		RecordClause[] _recordFitlerClause;
		public 
		{
			this(string recordFilterFile);
			int opApply(int delegate(ref RecordClause) dg);
			override string toString();
		}
	}
}
