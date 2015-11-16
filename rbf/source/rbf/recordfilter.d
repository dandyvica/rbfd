module rbf.recordfilter;

import std.stdio;
import std.file;
import std.string;
import std.algorithm;
import std.regex;
import std.exception;

// useful structure mapping a filter clause. Ex: FIELD == this is my field
struct RecordClause {
  string fieldName;   /// field name of the clause (e.g.: FIELD)
  string operator;    /// operator in the clause (e.g.: ==)
  string scalar;      /// value to match for (e.g.: "this is my field")
}

class RecordFilter {

private:

  RecordClause[] _recordFitlerClause;  // list of all clauses built from filter file

public:
  /**
	 * read the filter file and store the array of clauses
	 */
	this(string recordFilter, string separator)
	{
    // this is the regex to use to split the condition
		static auto reg = regex(r"(\w+)(\s*)(=|!=|>|<|~|!~|==)(\s*)(.+)$");

    // read filter file
		foreach (cond; recordFilter.split(separator))
		{
      // split filter clause into individual data
      auto m = matchAll(cond, reg);

      // build list of clauses
      _recordFitlerClause ~= RecordClause(
          m.captures[1].strip(),
          m.captures[3].strip(),
          m.captures[5].strip()
      );
		}
	}
  ///
  unittest {
    auto test = "a=1; c<3";
    auto cond = new RecordFilter(test, ";");
    assert(cond._recordFitlerClause[0].fieldName == "a");
    assert(cond._recordFitlerClause[0].operator == "=");
    assert(cond._recordFitlerClause[0].scalar == "1");
    assert(cond._recordFitlerClause[1].fieldName == "c");
    assert(cond._recordFitlerClause[1].operator == "<");
    assert(cond._recordFitlerClause[1].scalar == "3");
  }

  //@property auto recordClause() { return _recordFitlerClause; }

  /**
	 * to loop with foreach loop on all clases
	 *
	 * Examples:
	 * --------------
	 * foreach (clause c; all_clauses) { writeln(c); }
	 * --------------
	 */
  int opApply(int delegate(ref RecordClause) dg)
	{
		int result = 0;

		for (int i = 0; i < _recordFitlerClause.length; i++)
		{
		    result = dg(_recordFitlerClause[i]);
		    if (result)
			break;
		}
		return result;
	}

  override string toString() {
    auto s = "";

    foreach (RecordClause f; this) {
      s ~= "<'%s' '%s' '%s'>".format(f.fieldName, f.operator, f.scalar);
    }
    return s;
  }

}
