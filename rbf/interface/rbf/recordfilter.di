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
import rbf.options;
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
			this(string recordFilter, string separator = std.ascii.newline)
			{
				auto static reg = regex("(\\w+)\\s*(" ~ (cast(string[])[EnumMembers!Operator]).join('|') ~ ")\\s*(.+)$");
				foreach (m; splitIntoAtoms(recordFilter, separator, reg))
				{
					if (!m.empty)
					{
						auto op = m.captures[2].strip();
						if (!canFind(cast(string[])[EnumMembers!Operator], op))
						{
							throw new Exception(MSG030.format(op, cast(string[])[EnumMembers!Operator]));
						}
						_recordFitlerClause ~= RecordClause(m.captures[1].strip(), op, m.captures[3].strip());
					}
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
					s ~= "<'%s' '%s' '%s'>".format(f.fieldName, f.operator, f.value);
				}
				return s;
			}
		}
	}
}
