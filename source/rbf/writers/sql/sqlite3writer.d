module rbf.writers.sql.sqlite3writer;
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
import rbf.log;
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;
import rbf.writers.sql.sqlcommon;

alias compiledSqlStatement = sqlite3_stmt *;

immutable SQL_META   = `insert into meta values ("%s", "%s", %d);`;
immutable SQL_LAYOUT = "CREATE TABLE IF NOT EXISTS LAYOUT (RECNAME TEXT, RECDESC TEXT, RECLENGTH INTEGER, 
            FNAME TEXT, FDESC TEXT, FTYPE TEXT, FLENGTH INTEGER, FINDEX INTEGER, FOFFSET INTEGER);";

/*********************************************
 * in this case, each record is insert into a SQL table
 */
class Sqlite3Writer : Writer 
{

private:

    sqlite3* _db;                                     /// sqlite3 database handle
    int _sqlCode;                                     /// sqlite3 API return code
    compiledSqlStatement[string] _compiledInsertStmt; /// list of pre-build INSERT statements
    typeof(settings.outputConfiguration.sqlInsertPool) _trxCounter;  /// pool counter for grouping INSERTs
    string[string] _tableNames;                       /// aa to store record names vs table names

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
            logerr.info(Message.MSG063, stmt, _sqlCode, fromStringz(sqlite3_errmsg(_db)));
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
        auto stmt = SQL_INSERT.format(SqlCommon.buildTableName(rec.name), bind.join(","));
        log.trace(Message.MSG028, stmt);

        sqlite3_stmt *compiledStmt;
        _sqlCode = sqlite3_prepare_v2(_db, toStringz(stmt), to!int(stmt.length+1), &compiledStmt, null);
        if (_sqlCode != SQLITE_OK) 
        {
            logerr.info(Message.MSG029, _sqlCode, stmt, fromStringz(sqlite3_errmsg(_db)));
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
            // test first for null values: bind to NULL only for non string fields
            if (f.value == "" && f.type.meta.type != AtomicType.string) 
            {
                sqlite3_bind_null(_compiledInsertStmt[rec.name], to!int(f.context.index+1));
                continue;
            }

            // otherwise, bind value accorfing to its type
            try 
            {
                final switch (f.type.meta.type)
                {
                    case AtomicType.decimal:
                        _sqlCode = sqlite3_bind_double(_compiledInsertStmt[rec.name], to!int(f.context.index+1), to!double(f.value));
                        break;
                    case AtomicType.integer:
                        _sqlCode = sqlite3_bind_int64(_compiledInsertStmt[rec.name], to!int(f.context.index+1), to!long(f.value));
                        break;
                    case AtomicType.date:
                        _sqlCode = sqlite3_bind_text(_compiledInsertStmt[rec.name], to!int(f.context.index+1), toStringz(f.value), -1, SQLITE_TRANSIENT);
                        break;
                    case AtomicType.time:
                        _sqlCode = sqlite3_bind_text(_compiledInsertStmt[rec.name], to!int(f.context.index+1), toStringz(f.value), -1, SQLITE_TRANSIENT);
                        break;
                    case AtomicType.string:
                        _sqlCode = sqlite3_bind_text(_compiledInsertStmt[rec.name], to!int(f.context.index+1), toStringz(f.value), -1, SQLITE_TRANSIENT);
                        break;
                }
            }
            // conversion error catched
            catch (ConvException e) 
            {
                log.info(Message.MSG020, rec.meta.sourceLineNumber, rec.name, f.name, f.value, f.type.meta.type);

                // instead, use a NULL value
                _sqlCode = sqlite3_bind_null(_compiledInsertStmt[rec.name], to!int(f.context.index+1));
            }

            // test successful bind()
            if (_sqlCode != SQLITE_OK)
            {
                logerr.info(Message.MSG064.format(_sqlCode, fromStringz(sqlite3_errmsg(_db))));
            }
        }
    }

	/** 
     * Read external SQL statements file and execute all statements
	 *
	 * Params:
	 * 	sqlStmtFile = sql statements file name
	 *
	 */
    void _execStmtFile(string sqlStmtFile)
    {
		// check for SQL file existence
		enforce(exists(sqlStmtFile), Log.build_msg(Message.MSG073, sqlStmtFile));
        log.info(Message.MSG074, sqlStmtFile);

        // begin transaction
        _executeStmt("BEGIN IMMEDIATE TRANSACTION");

        // read each line and execute statement
        auto f = File(sqlStmtFile);
        f.byLine(KeepTerminator.yes, ';').each!(s => _executeStmt(s.dup));
        f.close;

        // commit
        _executeStmt("COMMIT TRANSACTION");
    }

	/** 
     * Populate LAYOUT table with layout data
	 *
	 * Params:
	 * 	layout = Layout object
	 *
	 */
    void _fillLayout(Layout layout)
    {
        string stmt = "insert into LAYOUT (RECNAME, RECDESC, RECLENGTH, FNAME, FDESC, FTYPE, FLENGTH, FINDEX, FOFFSET)
            values ('%s', '%s', '%s', '%s', '%s', '%s', %d, %d, %d);";

        // loop on each record and field
        foreach (rec; layout)
        {
            // do not include skipped records
            if (rec.meta.skipRecord) continue;

            // insert data for each record
            foreach (f; rec)
            {
                // and insert data
                _executeStmt(stmt.format(rec.name, rec.meta.description, rec.length, 
                            f.context.alternateName, f.description, f.type.meta.stringType, f.length, f.context.index+1, f.context.offset+1));
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
        // call root class (overwrite the file)
		super(databaseName);
        log.info(Message.MSG052, fromStringz(sqlite3_libversion()));

        _sqlCode = sqlite3_open(toStringz(databaseName), &_db);
        if(_sqlCode != SQLITE_OK)
        {
            log.fatal(Message.MSG047, sqlite3_errmsg(_db));
            throw new Exception(Message.MSG048.format(_sqlCode, databaseName, sqlite3_errmsg(_db)));
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
        // build table names to reuse if any
        _tableNames = SqlCommon.buildAllTableNames(layout);

        auto nbTables = 0;

        // creation of all tables
        log.info(Message.MSG021, settings.outputConfiguration.sqlInsertPool);

        // create all tables = one table per record
        _executeStmt("BEGIN IMMEDIATE TRANSACTION");
        foreach(rec; layout)
        {
            // create only for kept records after any potential field filter
            if (rec.meta.skipRecord) continue;

            // build statement
            auto stmt = SqlCommon.buildCreateTableStatement(rec);
            log.trace(Message.MSG028, stmt);

            // execute statement
            log.info(Message.MSG025, rec.name);
            _executeStmt(stmt);

            // one more table created
            nbTables++;

            // prepare further INSERT statements
            _prepareInsertCompiledStatement(rec);
        }

        // create layout table which could be useful in some situation
        _executeStmt(SQL_LAYOUT);

        // log tables creation
        log.info(Message.MSG025, "LAYOUT");
        log.info(Message.MSG022, nbTables+1);

        // now populate LAYOUT table for layout object
        _fillLayout(layout);
        log.info(Message.MSG072, "LAYOUT");

        // create all tables now!
        _executeStmt("COMMIT TRANSACTION");

        // if any, execute pre file statement
        if (settings.outputConfiguration.sqlPreFile != "")
        { 
            log.info(Message.MSG075, settings.outputConfiguration.sqlPreFile);
            _execStmtFile(settings.outputConfiguration.sqlPreFile);
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
        // make a transaction to group INSERTs
        if (_trxCounter == 0)
        {
            // insert using transaction
            _executeStmt("BEGIN IMMEDIATE TRANSACTION");
        }

        // bind varibles to values
        _bind(rec);

        // execute INSERT
        _sqlCode = sqlite3_step(_compiledInsertStmt[rec.name]);
        log.trace("%s", _compiledInsertStmt[rec.name]);
        if (_sqlCode != SQLITE_DONE) 
        {
            logerr.info(Message.MSG046, _sqlCode, fromStringz(sqlite3_errmsg(_db)));
        }
        else
        {
            sqlite3_reset(_compiledInsertStmt[rec.name]);
        }

        // it's time to clear bindings
        sqlite3_clear_bindings(_compiledInsertStmt[rec.name]);
        
        // TRX one more
        _trxCounter++;

        // end transaction if needed
        if (_trxCounter == settings.outputConfiguration.sqlInsertPool)
        {
            // insert using transaction
            _executeStmt("COMMIT TRANSACTION");

            // reset counter
            _trxCounter = 0;
        }

    }

    override void build(string rebuiltFileName) {}

	/** 
     * Close DB. First finish pending operations
	 */
	override void close() 
    {
        // excute pending transaction
        if (_trxCounter !=0) _executeStmt("COMMIT TRANSACTION");

        // compiled statement clean-up
        _compiledInsertStmt.each!(stmt => sqlite3_finalize(stmt));

        // if any, execute post file statement
        if (settings.outputConfiguration.sqlPostFile != "")
        {
            log.info(Message.MSG076, settings.outputConfiguration.sqlPostFile);
            _execStmtFile(settings.outputConfiguration.sqlPostFile);
        }

        // finally, close connection to DB
        sqlite3_close(_db);
	}

}
