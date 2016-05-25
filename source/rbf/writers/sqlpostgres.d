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
    void RbfPGConnect(const char *);
    void RbfPGExit();
    int RbfGetStatus(char *msg);
}

immutable conn_string = "user=sirax dbname=siraxdb";

/*********************************************
 * in this case, each record is insert into a SQL table
 */
class SqlPGWriter : Writer 
{

private:

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
        log.log(LogLevel.INFO, MSG092, PQlibVersion());

        // connect to PG
        RbfPGConnect(toStringz(conn_string));

        char *error_msg;
        auto status = RbfGetStatus(error_msg);
        auto msg = fromStringz(error_msg);

        if (status != 0)
        {
            // end up gracefully
            RbfPGExit();

            log.log(LogLevel.FATAL, MSG047, msg);
            throw new Exception(MSG093.format(status, databaseName, msg));
        }
	}

	override void prepare(Layout layout) {}
    override void build(string outputFileName) {}

    // identity is just printing out the same values than read
	override void write(Record rec) {}

}
