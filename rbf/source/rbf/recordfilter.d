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
	this(string recordFilterFile)
	{
		string[] cond;

    // file should exist
		enforce(exists(recordFilterFile), "record filter file %s not found".format(recordFilterFile));

    // this is the regex to use to split the condition
		static auto reg = regex(r"(\w+)(\s*)(=|!=|>|<|~|!~|==)(\s*)(.+)$");

    // read filter file
		foreach (string line_read; File(recordFilterFile, "r").lines)
		{
      auto line = line_read.strip();

      // comments ignored
			if (!line.startsWith("#")) {
        // split filter clause into individual data
        auto m = match(line, reg);

        // build list of clauses
        _recordFitlerClause ~= RecordClause(
            m.captures[1].strip(),
            m.captures[3].strip(),
            m.captures[5].strip()
        );
      }
		}
	}

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
