// D import file generated from 'source/rbf/recordfilter.d'
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
			this(string recordFilter, string separator)
			{
				auto static reg = regex("(\\w+)(\\s*)(=|!=|>|<|~|!~|==)(\\s*)(.+)$");
				foreach (cond; recordFilter.split(separator))
				{
					auto m = matchAll(cond, reg);
					_recordFitlerClause ~= RecordClause(m.captures[1].strip(), m.captures[3].strip(), m.captures[5].strip());
				}
			}
			int opApply(int delegate(ref RecordClause) dg)
			{
				int result = 0;
				for (int i = 0;
				 i < _recordFitlerClause.length; i++)
				{
					{
						result = dg(_recordFitlerClause[i]);
						if (result)
							break;
					}
				}
				return result;
			}
			override string toString()
			{
				auto s = "";
				foreach (RecordClause f; this)
				{
					s ~= "<'%s' '%s' '%s'>".format(f.fieldName, f.operator, f.scalar);
				}
				return s;
			}
		}
	}
}
