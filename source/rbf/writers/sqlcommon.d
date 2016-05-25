module rbf.writers.sqlcommon;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.conv;
import std.ascii;
import std.array;
import std.range;

import rbf.errormsg;
import rbf.log;
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;

immutable sqlKeywords = import("sqlkeywords.txt");

// list of SQL statements used for inserting record data
immutable SQL_CREATE = "create table if not exists %s (%s);";
immutable SQL_INSERT = "insert into %s values (%s);";
immutable SQL_META   = `insert into meta values ("%s", "%s", %d);`;

/*********************************************
 * generic class for managing SQL statement
 */
class SqlCommon
{

	/**
 	 * as SQL table names can't start with a number, if it's the case, just as R in front
     * of the record name
	 *
	 * Params:
	 * 	recordName = record name
	 *
	 */
    static string buildTableName(string recordName)
    {
        // build the list of SQL reserved keywords: it's used to check whether a record name is a reserved keyword
        static auto sqlKeywordsList = array(sqlKeywords.lineSplitter);
        sqlKeywordsList = array(sqlKeywordsList.filter!(f => f != ""));

        // is record name a reserved keywords? In that case, add 'R' in front of the record name
        if (sqlKeywordsList.canFind(recordName) || recordName[0].isDigit)
            return "R" ~ recordName;
        else
            return recordName;
    }


	/** 
     * Build the SQL statement used to create tables matching record
     * only create the table if it's not already existing
	 *
	 * Params:
	 * 	rec = Record object
	 *
	 */
    static string buildCreateTableStatement(Record rec)
    {
        auto cols = rec[].map!(f => buildColumnWithinCreateTableStatement(f));
        string stmt = SQL_CREATE.format(buildTableName(rec.name), join(cols, ","));
        return stmt;
    }

	/** 
     * Build the SQL colunm statement used in SQL create statement
     * The statement is highly dependant of the field type
	 *
	 * Params:
	 * 	f = Field object
	 *
	 */
    static string buildColumnWithinCreateTableStatement(Field f)
    {
        string colStmt;

        final switch (f.type.meta.type)
        {
            case AtomicType.decimal:
                colStmt = f.context.alternateName ~ " FLOAT";
                break;
            case AtomicType.integer:
                colStmt = f.context.alternateName ~ " INTEGER";
                break;
            case AtomicType.date:
                colStmt = f.context.alternateName ~ " DATE";
                break;
            case AtomicType.string:
                colStmt = "%s VARCHAR(%d)".format(f.context.alternateName, f.length);
                break;
        }
        return colStmt;
    }

}
