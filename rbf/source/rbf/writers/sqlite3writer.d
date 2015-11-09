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

immutable trxPool = 30;

/*********************************************
 * in this case, each record is displayed as an ASCII table
 */
class Sqlite3Writer : Writer {

private:

    sqlite3* _db;
    int _sqlCode;

    string[string] _insertStmt;         /// list of pre-build INSERT statements

    ushort _trxCounter;

    string _buildTableName(string s)
    {
        return s[0].isDigit ? "R" ~ s : s;
    }


    string _buildCreateTableStatement(Record rec)
    {
        auto cols = rec[].map!(f => _buildColumnWithinCreateTableStatement(f));
        auto tableName = _buildTableName(rec.name);
        string stmt = "create table if not exists %s (%s);".format(tableName, join(cols, ","));
        return stmt;
    }

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

    string _buildColumnWithinInsertStatement(Field f)
    {
        string colStmt;

        final switch (f.type.meta.type)
        {
            case AtomicType.decimal:
                colStmt = (f.value == "") ? "0" : f.value;
                break;
            case AtomicType.integer:
                colStmt = (f.value == "") ? "0" : f.value;
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

    void _executeStmt(string stmt)
    {
        _sqlCode = sqlite3_exec(_db, toStringz(stmt), null, null, null); 
        if (_sqlCode != SQLITE_OK) 
        {
            throw new Exception("error: SQL error %d, statement <%s>, error msg <%s>".format(_sqlCode, stmt, sqlite3_errmsg(_db)));
        }
    }

    void _prepareInsertStatement(Record rec)
    {
        _insertStmt[rec.name] = "insert into %s values (%%s);".format(_buildTableName(rec.name));
    }

public:

	this(in string outputFileName)
	{
		super(outputFileName, false);

        _sqlCode = sqlite3_open(toStringz(outputFileName), &_db);
        if(_sqlCode != SQLITE_OK)
        {
            stderr.writefln("error: database create error: %s\n", sqlite3_errmsg(_db));
            throw new Exception("error: SQL error %d when opening file %d, SQL msg %s ".format(_sqlCode, outputFileName, sqlite3_errmsg(_db)));
        }
	}

	override void prepare(Layout layout) 
    {
        // creation of all tables
        stderr.writeln("info: trying to create tables");

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
        if (_trxCounter == trxPool)
        {
            // insert using transaction
            _executeStmt("COMMIT TRANSACTION");

            // reset counter
            _trxCounter = 0;
        }

    }

	override void close() {
        sqlite3_close(_db);
	}

}
