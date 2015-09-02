module rbf.filter;

import std.stdio;
import std.file;
import std.string;
import std.algorithm;
import std.regex;
import std.exception;

// useful structure mapping a filter clause. Ex: FIELD == this is my field
struct Clause {
  string fieldName;   // field name of the clause (e.g.: FIELD)
  string operator;    // operator in the clause (e.g.: ==)
  string scalar;      // value to match for (e.g.: "this is my field")
}

class Filter {

private:

  Clause[] _fitlerClause;  // list of all clauses built from filter file

public:
  /**
	 * read the filter file and store the array of clauses
	 */
	this(string filterFile)
	{
		string[] cond;

    // file should exist
		enforce(exists(filterFile), "Filter file %s not found".format(filterFile));

    // this is the regex to use to split the condition
		static auto reg = regex(r"(\w+)(\s*)(=|!=|>|<|~|!~|==)(\s*)(.+)$");

    // read filter file
		foreach (string line_read; File(filterFile, "r").lines)
		{
      auto line = line_read.strip();
      
      writefln("line read <%s>", line);
      // comments ignored
			if (!startsWith(line, "#")) {
        // split filter clause into individual data
        auto m = match(line, reg);

        // build list of clauses
        _fitlerClause ~= Clause(
            m.captures[1].strip(),
            m.captures[3].strip(),
            m.captures[5].strip()
        );
      }
		}
    writeln(_fitlerClause);
	}

  /**
	 * to loop with foreach loop on all clases
	 *
	 * Examples:
	 * --------------
	 * foreach (clause c; all_clauses) { writeln(c); }
	 * --------------
	 */
  int opApply(int delegate(ref Clause) dg)
	{
		int result = 0;

		for (int i = 0; i < _fitlerClause.length; i++)
		{
		    result = dg(_fitlerClause[i]);
		    if (result)
			break;
		}
		return result;
	}

  override string toString() {
    auto s = "";

    foreach (Clause f; this) {
      s ~= "<%s %s %s>\n".format(f.fieldName, f.operator, f.scalar);
    }
    return s;
  }


}
