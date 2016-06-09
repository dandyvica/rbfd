module rbf.recordfilter;

import std.stdio;
import std.file;
import std.string;
import std.algorithm;
import std.regex;
import std.exception;
import std.array;
import std.traits;
import std.ascii;

import rbf.errormsg;
import rbf.fieldtype;
import rbf.field;
import rbf.options;
import rbf.log;

// useful structure mapping a filter clause. Ex: FIELD == this is my field
struct RecordClause 
{
  string fieldName;   /// field name of the clause (e.g.: FIELD)
  string operator;    /// operator in the clause (e.g.: >)
  TVALUE value;  /// value to match for (e.g.: "this is my field")
}

//auto opList = cast(string[]) [ EnumMembers!Operator ];
//auto recordFilterRegEx = r"(\w+)(\s*)(" ~ opList.join("|") ~ r")(\s*)(.+)$";

class RecordFilter 
{

private:

  RecordClause[] _recordFitlerClause;  // list of all clauses built from filter file or command line

public:
  /**
	 * read the filter file and store the array of clauses
	 */
	this(string recordFilter, string separator = newline)
	{
        // this is the regex to use to split the condition and recognize field name, operator and value
        // this regex is built dynamically from operator list
		static auto reg = regex(
                r"(\w+)\s*(" ~
                (cast(string[])[ EnumMembers!Operator ]).join('|') ~
                r")\s*(.+)$"
        );

        // get each match and create clause
        foreach (m; splitIntoAtoms(recordFilter, separator, reg))
        {
            // create clause if we have matched is condition
            if (!m.empty)
            {
                // check if operator is supported
                auto op = m.captures[2].strip();

                if (!canFind(cast(string[])[ EnumMembers!Operator ], op))
                {
                    throw new Exception(Message.MSG030.format(op, cast(string[])[ EnumMembers!Operator ]));
                }

                // build list of clauses
                _recordFitlerClause ~= RecordClause(m.captures[1].strip(), op, m.captures[3].strip());
            }
        }
	}
  ///
  unittest {
    auto test = "a=1; c<3";
    auto cond = new RecordFilter(test, ";");
    assert(cond._recordFitlerClause[0].fieldName == "a");
    assert(cond._recordFitlerClause[0].operator == "=");
    assert(cond._recordFitlerClause[0].value == "1");
    assert(cond._recordFitlerClause[1].fieldName == "c");
    assert(cond._recordFitlerClause[1].operator == "<");
    assert(cond._recordFitlerClause[1].value == "3");
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

  override string toString() 
  {
      auto s = "";

      foreach (RecordClause f; this) {
          s ~= "<'%s' '%s' '%s'>".format(f.fieldName, f.operator, f.value);
      }
      return s;
  }

}
