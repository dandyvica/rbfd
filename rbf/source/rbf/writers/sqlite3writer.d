module rbf.writers.sqlite3writer;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.conv;
import std.ascii;

import etc.c.sqlite3;

import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;

immutable sqlKeywords = import("sqlkeywords.txt");

/*********************************************
 * in this case, each record is insert into a SQL table
 */
class Sqlite3Writer : Writer {

private:

    sqlite3* _db;                                     /// sqlite3 database handle
    int _sqlCode;                                     /// sqlite3 API return code
    string[string] _insertStmt;                       /// list of pre-build INSERT statements
    typeof(outputFeature.insertPool) _trxCounter;     /// pool counter for grouping INSERTs
    string[] _sqlKeywordsList;                        /// list of all reserved keywords

	/**
 	 * as SQL table names can't start with a number, if it's the case, just as R in front
     * of the record name
	 *
	 * Params:
	 * 	recordName = record name
	 *
	 */
    string _buildTableName(string recordName)
    {
        // is record name a reserved keywords?
        if (_sqlKeywordsList.canFind(recordName) || recordName[0].isDigit)
            return "R" ~ recordName;
        else
            return recordName;
    }


	/** 
     * Build the SQL statement used to create tables matching record
     * only create the table if itt's not already existing
	 *
	 * Params:
	 * 	rec = Record object
	 *
	 */
    string _buildCreateTableStatement(Record rec)
    {
        auto cols = rec[].map!(f => _buildColumnWithinCreateTableStatement(f));
        auto tableName = _buildTableName(rec.name);
        string stmt = "create table if not exists %s (%s);".format(tableName, join(cols, ","));
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
    string _buildColumnWithinCreateTableStatement(Field f)
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

	/** 
     * Build the SQL colunm statement used in SQL insert statement
     * The statement is highly dependant of the field type
     * For empty fields, we just use the SQL NULL value
	 *
	 * Params:
	 * 	f = Field object
	 *
	 */
    string _buildColumnWithinInsertStatement(Field f)
    {
        string colStmt;

        // if empty, it means it's an SQL NULL value
        if (f.value == "") return "NULL";

        final switch (f.type.meta.type)
        {
            case AtomicType.decimal:
                colStmt = (f.value == "") ? "NULL" : f.value;
                break;
            case AtomicType.integer:
                colStmt = (f.value == "") ? "NULL" : f.value;
                break;
            case AtomicType.date:
                colStmt = f.value;
                break;
            case AtomicType.string:
                colStmt = `"%s"`.format(f.value);
                break;
        }
        return colStmt;
    }

	/** 
     * SQL statement execution. Throws an exception if an SQL error is returned
	 *
	 * Params:
	 * 	stmt = SQL statement 
	 *
	 */
    void _executeStmt(string stmt)
    {
        _sqlCode = sqlite3_exec(_db, toStringz(stmt), null, null, null); 
        if (_sqlCode != SQLITE_OK) 
        {
            throw new Exception("error: SQL error %d, statement <%s>, error msg <%s>".format(_sqlCode, stmt, fromStringz(sqlite3_errmsg(_db))));
        }
    }

	/** 
     * Build INSERT statements in advance because it's only depending on record
	 *
	 * Params:
	 * 	rec = Record object
	 *
	 */
    void _prepareInsertStatement(Record rec)
    {
        _insertStmt[rec.name] = "insert into %s values (%%s);".format(_buildTableName(rec.name));
    }

public:

	/** 
     * Create writer: open the sqlite3 database (and create it if not existing).
	 *
	 * Params:
	 * 	databaseName = name of the output db to create
	 *
	 */
	this(in string databaseName)
	{
        // call root class but don't create the file
		super(databaseName, false);

        _sqlCode = sqlite3_open(toStringz(databaseName), &_db);
        if(_sqlCode != SQLITE_OK)
        {
            stderr.writefln("error: database create error: %s\n", sqlite3_errmsg(_db));
            throw new Exception("error: SQL error %d when opening file %d, SQL msg %s ".format(_sqlCode, databaseName, sqlite3_errmsg(_db)));
        }
	}

	/** 
     * Build all SQL statements for each record
	 *
	 * Params:
	 * 	layout = Layout object
	 *
	 */
	override void prepare(Layout layout) 
    {
        // build the list of SQL reserved keywords: it's used to check whether a record name is a reserved keyword
        _sqlKeywordsList = sqlKeywords.split('\n');
        writefln("kwlist=%s",_sqlKeywordsList);

        // creation of all tables
        stderr.writeln("info: trying to create tables, SQL pool=%d".format(outputFeature.insertPool));

        // create all tables = one table per record
        foreach(rec; layout)
        {
            // build statement
            auto stmt = _buildCreateTableStatement(rec);
            //writefln("CREATE TABLE sql=<%s>",stmt);

            // execute statement
            _executeStmt(stmt);
            //writefln("CREATE TABLE sqlcode=%d",_sqlCode);


            // prepare further INSERT statements
            _prepareInsertStatement(rec);
            //writeln(_insertStmt[rec.name]);
        }
    }

	/** 
     * Insert data into SQL table. Use a SQL transaction to speed-up process.
     * The COMMIT transaction is done every n INSERTs. The value n is given by
     * a parameter from the rbf.xml configuration file.
	 *
	 * Params:
	 * 	rec = Record object
	 *
	 */
	override void write(Record rec)
	{
        auto values = rec[].map!(f => _buildColumnWithinInsertStatement(f));
        auto stmt = _insertStmt[rec.name].format(join(values, ","));

        // make a transaction to group INSERTs
        if (_trxCounter == 0)
        {
            // insert using transaction
            _executeStmt("BEGIN IMMEDIATE TRANSACTION");
        }

        // execute insert
        _executeStmt(stmt);

        // TRX one more
        _trxCounter++;

        // end transaction if needed
        if (_trxCounter == outputFeature.insertPool)
        {
            // insert using transaction
            _executeStmt("COMMIT TRANSACTION");

            // reset counter
            _trxCounter = 0;
        }

    }

	/** 
     * Close DB.
	 */
	override void close() {
        sqlite3_close(_db);
	}

}
