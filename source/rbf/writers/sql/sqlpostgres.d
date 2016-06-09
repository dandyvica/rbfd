module rbf.writers.sql.sqlpostgres;
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
import rbf.writers.sql.sqlcommon;

extern (C) {
    // from PG standard lib
    int  PQlibVersion();

    // from specific lib
    void rbfPGConnect(const char *);
    void rbfPGExit();
    int  rbfPGGetStatus();
    char *rbfPGGetErrorMsg();
    int  rbfPGExecStmt(const char *stmt);
    int  rbfPGPrepare(const char *stmt, ulong nbCols);
    char *rbfPGGetSeq();
}

/*********************************************
 * in this case, each record is insert into a SQL table
 */
class SqlPGWriter : Writer 
{

private:

    string[string] _insertStmt;          /// list of SQL INSERT statements for each record
    string[string] _copyStmt;            /// list of SQL INSERT statements for each record
    string[string] _tableNames;          /// aa to store record names vs table names
    typeof(settings.outputConfiguration.sqlInsertPool) _trxCounter;     /// pool counter for grouping INSERTs
    string[][string] _groupedInsert;
    string _lastSeq;

    string[string] _insertPreparedStmt;

    // connect to PG
    void _connect()
    {
        log.info(Message.MSG092, PQlibVersion(), settings.outputConfiguration.connectionString);

        // connect to PG
        rbfPGConnect(toStringz(settings.outputConfiguration.connectionString));

        auto status = rbfPGGetStatus();
        if (status != 0)
        {
            // get error message
            auto sql_error_msg = fromStringz(rbfPGGetErrorMsg()).dup.strip;

            // end up gracefully
            rbfPGExit();

            // log error and abort
            log.fatal(Message.MSG047, sql_error_msg);
            throw new Exception(Message.MSG093.format(status, settings.outputConfiguration.connectionString, sql_error_msg));
        }

        // set warning message to get rid of NOTICE messages
        _executeStmt("set client_min_messages to warning");
    }

    // build all INSERT statements
    void _buildInsertStatements(Layout layout)
    {
        immutable SQL_INSERT_WITH_ID = "INSERT INTO %s VALUES (%s,%s)";
        foreach (rec; layout)
        {
            _insertStmt[rec.name] = SQL_INSERT_WITH_ID.format(_tableNames[rec.name], _lastSeq, "%s");
        }
    }

    // build all INSERT statements
    void _buildCopyStatements(Layout layout)
    {
        immutable SQL_COPY_WITH_ID = "COPY %s FROM STDIN WITH FORMAT CSV ";
        foreach (rec; layout)
        {
            _copyStmt[rec.name] = SQL_COPY_WITH_ID.format(_tableNames[rec.name]);
        }
    }

    // build all INSERT statements
    void _buildPreparedInsertStatements(Layout layout)
    {
        immutable SQL_INSERT_WITH_ID = "INSERT INTO %s VALUES (%s)";

        // now build insert prepared stmt
        foreach (rec; layout)
        {
            string[] vars;
            // end up with +1 because we need to add the ID variable
            foreach (i; 1..rec.size+1) { vars ~= "$" ~ to!string(i); }

            _insertPreparedStmt[rec.name] = SQL_INSERT_WITH_ID.format(_tableNames[rec.name], vars.join(","));

            rbfPGPrepare(_insertPreparedStmt[rec.name].toStringz, rec.size+1);
            writeln(_insertPreparedStmt[rec.name]);
        }
    }

    // create schema for gathering layouts
    void _createSchema(Layout layout)
    {
        if (layout.meta.schema != "")
        {
            _executeStmt("BEGIN TRANSACTION");
            _executeStmt("CREATE SCHEMA IF NOT EXISTS " ~ layout.meta.schema ~ " ;");
            _executeStmt("COMMIT TRANSACTION");
        }
    }

    // create meta index table to keep track of inserted files and dates
    void _createMeta(Layout layout)
    {
        auto boxInsert = "INSERT INTO BOXES VALUES(DEFAULT,'%s','%s','%s',current_timestamp)";
        // create table nd insert data for this insert
        _executeStmt("BEGIN TRANSACTION");
        _executeStmt("CREATE TABLE IF NOT EXISTS BOXES 
                (ID SERIAL PRIMARY KEY, FILENAME TEXT, LAYOUT_FILE TEXT, DOMAIN TEXT, INSERT_DATE TIMESTAMP)");
        _executeStmt(boxInsert.format(
                    settings.cmdLineOptions.cmdLineArgs.inputFileName,
                    layout.meta.file, 
                    layout.meta.schema)
        );

        // get back ID
        _lastSeq = fromStringz(rbfPGGetSeq()).idup;
        _executeStmt("COMMIT TRANSACTION");
    }

    // create schema and all tables for inserting data
    void _createTables(Layout layout)
    {
        auto nbTables = 0;

        // creation of all tables
        log.info(Message.MSG095, settings.outputConfiguration.sqlInsertPool, settings.outputConfiguration.sqlGroupedInsertPool);

        // create all tables = one table per record
        _executeStmt("BEGIN TRANSACTION");
        foreach(rec; layout)
        {
            // create only for kept records after any potential field filter
            if (rec.meta.skipRecord) continue;

            // build statement
            auto stmt = SqlCommon.buildCreateTableStatement(rec, layout.meta.schema);
            log.trace(Message.MSG028, stmt);

            // execute statement
            log.info(Message.MSG025, rec.name);
            _executeStmt(stmt);

            // one more table created
            nbTables++;

            // add table comment
            stmt = "COMMENT ON TABLE %s IS '%s'".format(_tableNames[rec.name], rec.meta.description);
            _executeStmt(stmt);

            // add column comment
            foreach (f; rec)
            {
                stmt = "COMMENT ON COLUMN %s.%s IS '%s'".format(_tableNames[rec.name], f.context.alternateName, f.description);
                _executeStmt(stmt);
            }

            // prepare further INSERT statements
            //_prepareInsertCompiledStatement(rec);
            _groupedInsert[rec.name] = [];
            _groupedInsert[rec.name].reserve(settings.outputConfiguration.sqlGroupedInsertPool);

        }

        // log tables creation
        log.info(Message.MSG022, nbTables);

        // create all tables now!
        _executeStmt("COMMIT TRANSACTION");
    }

    // build all the values to insert
    auto _buildInsertValues(Record rec)
    {
        string[] fields;
        foreach (f; rec)
        {
            // if any case, if value is "", just set value to NULL
            if (f.value == "") 
            {
                fields ~= "NULL";
            }
            else
            {
                // otherwise, bind value according to its type
                try 
                {
                    final switch (f.type.meta.type)
                    {
                        case AtomicType.decimal:
                            // try to convert first to binary type. It will handle problems where the data is not as the same type
                            // of the column (ex: string for a float column). In this case, this is reset to NULL
                            auto d = to!double(f.value);
                            fields ~= "%s".format(f.value);
                            break;
                        case AtomicType.integer:
                            auto l = to!long(f.value);
                            fields ~= "%s".format(f.value);
                            break;
                        case AtomicType.date:
                        case AtomicType.time:
                            // sometimes, time or date is filled with 0. In that case, set to NULL
                            if (f.value.removechars("0") == "" || f.value.removechars("0123456789") != "")
                                fields ~= "NULL";
                            else
                                fields ~= "'%s'".format(f.value);
                            break;
                        case AtomicType.string:
                            // new to sanitize string because sometimes, it contains non-printable chars
                            fields ~= "'%s'".format(f.sanitize(f.value));
                            break;
                    }
                }
                // conversion error catched
                catch (ConvException e) 
                {
                    log.info(Message.MSG020, rec.meta.sourceLineNumber, rec.name, f.name, f.value, f.type.meta.type);

                    // instead, use a NULL value
                    fields ~= "NULL";
                }
            }

        }

        return "(%s,%s)".format(_lastSeq, fields.join(","));
    }

    auto _buildLargeInsert(string tableName, string[] data)
    {
        static immutable insertStmt = "INSERT INTO %s VALUES %s";
        return insertStmt.format(tableName, data.join(","));
    }

    void _writeWithInsert(Record rec)
    {
        // build grouped statements per record
        _groupedInsert[rec.name] ~= _buildInsertValues(rec);
        if (_groupedInsert[rec.name].length == settings.outputConfiguration.sqlGroupedInsertPool)
        {
            //auto largeInsert = "INSERT INTO %s VALUES %s".format(_tableNames[rec.name], _groupedInsert[rec.name].join(","));
            auto largeInsert = _buildLargeInsert(_tableNames[rec.name], _groupedInsert[rec.name]);
            _executeStmt("BEGIN TRANSACTION");
            _executeStmt(largeInsert);
            //log.info("stmt for record name %s", rec.name);
            _executeStmt("COMMIT TRANSACTION");
            _groupedInsert[rec.name] = [];
        }
    }

    void _writeWithCopy(Record rec)
    {
    }

    // execute a PG SQL statement
    void _executeStmt(string stmt)
    {
        auto rc = rbfPGExecStmt(stmt.toStringz);
        if (rc != 1)
        {
            auto sql_error_msg = fromStringz(rbfPGGetErrorMsg()).dup.strip;
            log.fatal(Message.MSG094, rc, stmt, sql_error_msg);
            throw new Exception(Message.MSG094.format(rc, stmt, sql_error_msg));
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
	this(in string outputFileName)
	{
        // call root class (overwrite the file)
        super();
	}

	override void prepare(Layout layout)
    {
        // first, connect to PG. Need to call here in prepare() because we only know settings at this point.
        _connect();

        // build table names to reuse if any
        _tableNames = SqlCommon.buildAllTableNames(layout);

        // create schema
        _createSchema(layout);

        // create DB structure
        _createTables(layout);

        // create table for keeping track of all that stuff
        _createMeta(layout);

        // build INSERT statements to be used
        _buildInsertStatements(layout);
        //_buildPreparedInsertStatements(layout);
    }

    override void build(string outputFileName) {}

    // identity is just printing out the same values than read
	override void write(Record rec) 
    {
        _writeWithInsert(rec);
    }

    // identity is just printing out the same values than read
    /*
	override void write(Record rec) 
    {
        // make a transaction to group INSERTs
        if (_trxCounter == 0)
        {
            // insert using transaction
            _executeStmt("BEGIN TRANSACTION");
        }

        // build grouped statements per record
        _groupedInsert[rec.name] ~= _buildInsertValues(rec);
        if (_groupedInsert[rec.name].length == settings.outputConfiguration.sqlGroupedInsertPool)
        {
            auto largeInsert = _buildLargeInsert(_tableNames[rec.name], _groupedInsert[rec.name]);
            _executeStmt(largeInsert);
            _groupedInsert[rec.name] = [];
        }


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
    */

	/** 
     * Close DB. First finish pending operations
	 */
    override void close() 
    {
        // first execute pending grouped inserts
        foreach (recname; _groupedInsert.byKey)
        {
            if (_groupedInsert[recname] != [])
            {
                //auto largeInsert = "INSERT INTO %s VALUES %s".format(_tableNames[recname], _groupedInsert[recname].join(","));
                auto largeInsert = _buildLargeInsert(_tableNames[recname], _groupedInsert[recname]);
                _executeStmt("BEGIN TRANSACTION");
                _executeStmt(largeInsert);
                _executeStmt("COMMIT TRANSACTION");
            }
        }

        // excute pending transaction
        if (_trxCounter !=0) _executeStmt("COMMIT TRANSACTION");

        // end up gracefully
        rbfPGExit();
    }
}
