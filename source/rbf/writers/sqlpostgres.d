module rbf.writers.sqlpostgres;
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
import rbf.writers.sqlcommon;

extern (C) {
    // from PG standard lib
    int  PQlibVersion();

    // from specific lib
    void rbfPGConnect(const char *);
    void rbfPGExit();
    int rbfGetPGStatus();
    char *rbfGetErrorMsg();
    int rbfExecStmt(const char *stmt);
    char *rbfGetSeq();
}

/*********************************************
 * in this case, each record is insert into a SQL table
 */
class SqlPGWriter : Writer 
{

private:

    string[string] _insertStmt;         /// list of SQL INSERT statements for each record
    string[string] _tableNames;         /// aa to store record names vs table names
    typeof(outputFeature.sqlInsertPool) _trxCounter;     /// pool counter for grouping INSERTs
    string[][string] _groupedInsert;
    string _lastSeq;

    // connect to PG
    void _connect()
    {
        log.log(LogLevel.INFO, MSG092, PQlibVersion(), outputFeature.connectionString);

        // connect to PG
        rbfPGConnect(toStringz(outputFeature.connectionString));

        auto status = rbfGetPGStatus();
        if (status != 0)
        {
            // get error message
            auto error_msg = fromStringz(rbfGetErrorMsg()).dup.strip;

            // end up gracefully
            rbfPGExit();

            log.log(LogLevel.FATAL, MSG047, error_msg);
            throw new Exception(MSG093.format(status, outputFeature.connectionString, error_msg));
        }
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
                    cmdLineOptions.cmdLineArgs.inputFileName,
                    layout.meta.file, 
                    layout.meta.schema)
        );

        // get back ID
        _lastSeq = fromStringz(rbfGetSeq()).idup;
        _executeStmt("COMMIT TRANSACTION");
    }

    // create schema and all tables for inserting data
    void _createTables(Layout layout)
    {
        auto nbTables = 0;

        // creation of all tables
        log.log(LogLevel.INFO, MSG021, outputFeature.sqlInsertPool);

        // create all tables = one table per record
        _executeStmt("BEGIN TRANSACTION");
        foreach(rec; layout)
        {
            // create only for kept records after any potential field filter
            if (rec.meta.skipRecord) continue;

            // build statement
            auto stmt = SqlCommon.buildCreateTableStatement(rec, layout.meta.schema);
            log.log(LogLevel.TRACE, MSG028, stmt);

            // execute statement
            log.log(LogLevel.INFO, MSG025, rec.name);
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
            _groupedInsert[rec.name].reserve(outputFeature.sqlGroupedInsertPool);

        }

        // log tables creation
        log.log(LogLevel.INFO, MSG022, nbTables);

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
                // depending on type, inserting data in not straightforward
                final switch (f.type.meta.type)
                {
                    case AtomicType.decimal:
                        fields ~= "%s".format(f.value);
                        break;
                    case AtomicType.integer:
                        fields ~= "%s".format(f.value);
                        break;
                    case AtomicType.date:
                        fields ~= "'%s'".format(f.value);
                        break;
                    case AtomicType.time:
                        fields ~= "'%s'".format(f.value);
                        break;
                    case AtomicType.string:
                        fields ~= "'%s'".format(f.value);
                        break;
                }
            }

        }

        return "(%s,%s)".format(_lastSeq, fields.join(","));
    }

    // execute a PG SQL statement
    void _executeStmt(string stmt)
    {
        auto rc = rbfExecStmt(stmt.toStringz);
        if (rc != 1)
        {
            auto error_msg = fromStringz(rbfGetErrorMsg()).dup.strip;
            log.log(LogLevel.FATAL, MSG094, rc, stmt, error_msg);
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
        // first, connect to PG
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
    }

    override void build(string outputFileName) {}

    // identity is just printing out the same values than read
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
        if (_groupedInsert[rec.name].length == outputFeature.sqlGroupedInsertPool)
        {
            auto largeInsert = "INSERT INTO %s VALUES %s".format(_tableNames[rec.name], _groupedInsert[rec.name].join(","));
            _executeStmt(largeInsert);
            _groupedInsert.clear;
        }


        // build insert values (after the VALUES keyword of INSERT stmt and insert
        /*
        auto finalInsert =  "INSERT INTO %s VALUES %s".format(_tableNames[rec.name], _buildInsertValues(rec)); 
        _executeStmt(finalInsert);
        */

        // TRX one more
        _trxCounter++;

        // end transaction if needed
        if (_trxCounter == outputFeature.sqlInsertPool)
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
    override void close() 
    {
        // first execute pending grouped inserts
        foreach (recname; _groupedInsert.byKey)
        {
            if (_groupedInsert[recname] != [])
            {
                auto largeInsert = "INSERT INTO %s VALUES %s".format(_tableNames[recname], _groupedInsert[recname].join(","));
                _executeStmt(largeInsert);
            }
        }

        // excute pending transaction
        if (_trxCounter !=0) _executeStmt("COMMIT TRANSACTION");

        // end up gracefully
        rbfPGExit();
    }
}
