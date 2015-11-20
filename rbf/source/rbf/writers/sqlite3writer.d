module rbf.writers.sqlite3writer;
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

import etc.c.sqlite3;

import rbf.errormsg;
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;

immutable sqlKeywords = import("sqlkeywords.txt");
alias compiledSqlStatement = sqlite3_stmt *;

/*********************************************
 * in this case, each record is insert into a SQL table
 */
class Sqlite3Writer : Writer {

private:

    sqlite3* _db;                                     /// sqlite3 database handle
    int _sqlCode;                                     /// sqlite3 API return code
    compiledSqlStatement[string] _compiledInsertStmt; /// list of pre-build INSERT statements
    //string[string] _insertStmt;                       /// list of pre-build INSERT statements
    typeof(outputFeature.insertPool) _trxCounter;     /// pool counter for grouping INSERTs
    string[] _sqlKeywordsList;                        /// list of all SQLITE3 reserved keywords

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
            stderr.writeln("error: statement <%s>, error code = <%d>, error msg <%s>".format(stmt, _sqlCode, fromStringz(sqlite3_errmsg(_db))));
        }
    }

	/** 
     * Build INSERT statements in advance because it's only depending on record
	 *
	 * Params:
	 * 	rec = Record object
	 *
	 */
    void _prepareInsertCompiledStatement(Record rec)
    {
        auto bind = array(repeat("?", rec.size));
        auto stmt = "insert into %s values (%s);".format(_buildTableName(rec.name), bind.join(","));
        log.log(LogLevel.TRACE, MSG028, stmt);

        sqlite3_stmt *compiledStmt;
        _sqlCode = sqlite3_prepare_v2(_db, toStringz(stmt), to!int(stmt.length), &compiledStmt, null);
        if (_sqlCode != SQLITE_OK) 
        {
            stderr.writefln(MSG029, _sqlCode, stmt, fromStringz(sqlite3_errmsg(_db)));
        }
        else
        {
            _compiledInsertStmt[rec.name] = compiledStmt;
        }
    }

	/** 
     * Bind field values to each SQL INSERT variable
	 *
	 * Params:
	 * 	rec = Record object
	 *
	 */
    void _bind(Record rec)
    {
        foreach (f; rec)
        {
            // test first for null values
            if (f.value == "") 
            {
                sqlite3_bind_null(_compiledInsertStmt[rec.name], to!int(f.context.index+1));
                continue;
            }

            // otherwise, bind value accorfing to its type
            try {
                final switch (f.type.meta.type)
                {
                    case AtomicType.decimal:
                        _sqlCode = sqlite3_bind_double(_compiledInsertStmt[rec.name], to!int(f.context.index+1), to!double(f.value));
                        break;
                    case AtomicType.integer:
                        _sqlCode = sqlite3_bind_int(_compiledInsertStmt[rec.name], to!int(f.context.index+1), to!int(f.value));
                        break;
                    case AtomicType.date:
                        _sqlCode = sqlite3_bind_text(_compiledInsertStmt[rec.name], to!int(f.context.index+1), toStringz(f.value), -1, SQLITE_STATIC);
                        break;
                    case AtomicType.string:
                        _sqlCode = sqlite3_bind_text(_compiledInsertStmt[rec.name], to!int(f.context.index+1), toStringz(f.value), -1, SQLITE_STATIC);
                        break;
                }
            }
            // conversion error catched
            catch (ConvException e) {
                log.log(LogLevel.INFO, MSG020, f.name, f.value, f.type.meta.type);
                // instead, use a NULL value
                _sqlCode = sqlite3_bind_null(_compiledInsertStmt[rec.name], to!int(f.context.index+1));
            }

            // test successful bind()
            if (_sqlCode != SQLITE_OK)
            {
                stderr.writeln("error: sqlite_bind() API error, error code = <%d>, error msg <%s>".format(_sqlCode, fromStringz(sqlite3_errmsg(_db))));
            }
        }
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
		super(databaseName);

        _sqlCode = sqlite3_open(toStringz(databaseName), &_db);
        if(_sqlCode != SQLITE_OK)
        {
            stderr.writefln("error: database create error: %s\n", sqlite3_errmsg(_db));
            throw new Exception("error: SQL error %d when opening file %d, SQL msg %s ".format(_sqlCode, databaseName, sqlite3_errmsg(_db)));
        }
        log.log(LogLevel.INFO, MSG019, databaseName);
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
        auto nbTables = 0;

        // build the list of SQL reserved keywords: it's used to check whether a record name is a reserved keyword
        _sqlKeywordsList = sqlKeywords.split('\n');
        _sqlKeywordsList = array(_sqlKeywordsList.filter!(f => f != ""));

        // creation of all tables
        log.log(LogLevel.INFO, MSG021, outputFeature.insertPool);

        // create all tables = one table per record
        foreach(rec; layout)
        {
            // create only for kept records after any potential field filter
            if (rec.meta.skip) continue;

            // build statement
            auto stmt = _buildCreateTableStatement(rec);
            log.log(LogLevel.TRACE, MSG028, stmt);

            // execute statement
            log.log(LogLevel.INFO, MSG025, rec.name);
            _executeStmt(stmt);

            // one more table created
            nbTables++;

            // prepare further INSERT statements
            _prepareInsertCompiledStatement(rec);
            log.log(LogLevel.INFO, MSG025, rec.name);
            //_prepareInsertStatement(rec);
        }
        log.log(LogLevel.INFO, MSG022, nbTables);
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
        // make a transaction to group INSERTs
        if (_trxCounter == 0)
        {
            // insert using transaction
            _executeStmt("BEGIN IMMEDIATE TRANSACTION");
        }

        // insert
        _bind(rec);
        _sqlCode = sqlite3_step(_compiledInsertStmt[rec.name]);
        if (_sqlCode != SQLITE_DONE) 
        {
            stderr.writeln("error: INSERT statement, error code = <%d>, error msg <%s>".format(_sqlCode, fromStringz(sqlite3_errmsg(_db))));
        }
        else
        {
            sqlite3_reset(_compiledInsertStmt[rec.name]);
        }
        
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
     * Close DB. First finish pending operations
	 */
	override void close() {
        // excute pending transaction
        if (_trxCounter !=0) _executeStmt("COMMIT TRANSACTION");

        // compiled statement clean-up
        _compiledInsertStmt.each!(stmt => sqlite3_finalize(stmt));

        // finally, close connection to DB
        sqlite3_close(_db);
	}

}
