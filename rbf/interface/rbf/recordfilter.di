// D import file generated from 'source/rbf/recordfilter.d'
module rbf.recordfilter;
import std.stdio;
import std.file;
import std.string;
import std.algorithm;
import std.regex;
import std.exception;
import std.array;
import std.traits;
import rbf.errormsg;
import rbf.fieldtype;
import rbf.field;
struct RecordClause
{
	string fieldName;
	string operator;
	TVALUE value;
}
class RecordFilter
{
	private 
	{
		RecordClause[] _recordFitlerClause;
		public 
		{
			this(string recordFilter, string separator);
			int opApply(int delegate(ref RecordClause) dg);
			override string toString();
		}
	}
}
