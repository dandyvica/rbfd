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

/*********************************************
 * in this case, each record is displayed as an ASCII table
 */
class Sqlite3Writer : Writer {

private:

    sqlite3* _db;
    int _sqlCode;

    string[string] _insertStmt;         /// list of pre-build INSERT statements

    string _buildTableName(string s)
    {
        return s[0].isDigit ? "R" ~ s : s;
    }


    string _buildCreateTableStatement(Record rec)
    {
        auto cols = rec[].map!(f => _buildColumnWithinCreateTableStatement(f));
        auto tableName = _buildTableName(rec.name);
        string stmt = "create table %s (%s);".format(tableName, join(cols, ","));
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
                break;
            case AtomicType.integer:
                colStmt = f.value;
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

    int _executeStmt(string stmt)
    {
        return sqlite3_exec(_db, toStringz(stmt), null, null, null); 
    }

    void _prepareInsertStatement(Record rec)
    {
        _insertStmt[rec.name] = "insert into %s values (%%s)".format(_buildTableName(rec.name));
    }

public:

	this(in string outputFileName)
	{
		super(outputFileName);

        _sqlCode = sqlite3_open("file.db", &_db);
        if(_sqlCode != SQLITE_OK)
        {
            stderr.writefln("error: database create error: %s\n", sqlite3_errmsg(_db));
            return;
        }
        printf("DB open!\n");
	}

	override void prepare(Layout layout) 
    {
        // creation of all tables
        stderr.writeln("info: creating tables");

        // create all tables = one table per record
        foreach(rec; layout)
        {
            // build statement
            auto stmt = _buildCreateTableStatement(rec);

            // execute statement
            _sqlCode = _executeStmt(stmt);

            // prepare further INSERT statements
            _prepareInsertStatement(rec);
            writeln(_insertStmt[rec.name]);
        }
        _sqlCode = _executeStmt("COMMIT;");
        //writeln(_sqlCode);

        // build INSERT statements



    }

	override void write(Record rec)
	{
        auto values = rec[].map!(f => _buildColumnWithinInsertStatement(f));

        auto stmt = _insertStmt[rec.name].format(values);

        _sqlCode = _executeStmt(stmt);
        writeln(_sqlCode);
        _sqlCode = _executeStmt("COMMIT;");
        writeln(_sqlCode);
    }

	override void close() {
        sqlite3_close(_db);
	}

}
