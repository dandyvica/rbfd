module rbf.writers.sql.sqlcommon;
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

// list of SQL reserved keywords: this is used to check whether the record name could be used
// as a table name, and is not reserved for SQL
immutable sqlKeywords = import("sqlkeywords.txt");

// list of SQL statements used for inserting record data
immutable SQL_CREATE = "CREATE TABLE IF NOT EXISTS %s (%s);";
immutable SQL_CREATE_WITH_ID = "CREATE TABLE IF NOT EXISTS %s (ID INTEGER, %s);";
immutable SQL_INSERT = "INSERT INTO %s VALUES (%s);";
//immutable SQL_INSERT_WITH_ID = "INSERT INTO %s VALUES (%d,%s);";
immutable SQL_META   = `INSERT INTO META VALUES ("%s", "%s", %d);`;

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
 	 * buld the list of all table names 
	 *
	 * Params:
	 * 	layout = Layout object
	 *
	 */
    static auto buildAllTableNames(Layout layout)
    {
        string[string] tableNames;

        // no schema? simple table names though
        if (layout.meta.schema == "")
        {
            foreach (rec; layout) { tableNames[rec.name] = SqlCommon.buildTableName(rec.meta.tableName); }
        }
        else
        {
            foreach (rec; layout) { tableNames[rec.name] = layout.meta.schema ~ "." ~ SqlCommon.buildTableName(rec.meta.tableName); }
        }

        return tableNames;
    }

	/** 
     * Build the SQL statement used to create tables matching record
     * only create the table if it's not already existing
	 *
	 * Params:
	 * 	rec = Record object
	 *
	 */
    static string buildCreateTableStatement(Record rec, string schema="")
    {
        auto cols = rec[].map!(f => buildColumnWithinCreateTableStatement(f));
        string stmt;

        // create with prepend schema if any
        if (schema == "")
            stmt = SQL_CREATE.format(buildTableName(rec.meta.tableName), join(cols, ","));
        else
            stmt = SQL_CREATE_WITH_ID.format(schema ~ "." ~ buildTableName(rec.meta.tableName), join(cols, ","));
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
                colStmt = f.context.alternateName ~ " BIGINT";
                break;
            case AtomicType.time:
                colStmt = f.context.alternateName ~ " TIME";
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
