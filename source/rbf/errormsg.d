module rbf.errormsg;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.algorithm;
import std.conv;
import std.datetime;
import std.file;
import std.process;
import std.range;
import std.stdio;
import std.string;

enum Message: string 
{
        MSG001 = "error: element name <%s> is not in record/container <%s>",
        MSG002 = "line# <%d>, record <%s>, field <%s>, value <%s> is not matching expected pattern <%s>",
        MSG003 = "name=<%s>, description=<%s>, length=<%u>, type=<%s>, lower/upperBound=<%u:%u>, rawValue=<%s>, value=<%s>, offset=<%s>, index=<%s>",
        MSG004 = "error: settings file <%s> not found",
        MSG005 = "error: element %s, index %d is out of bounds",
        MSG006 = "error: cannot call get method with index %d without allowing duplicated",
        MSG007 = "error: lower index %d is out of bounds, upper bound = %d",
        MSG008 = "error: upper index %d is out of bounds, upper bound = %d",
        MSG009 = "error: lower index %d is higher than upper index %d",
        MSG010 = "error: unable to create field, wrong number of csv data (%d, expected %d)",
        MSG011 = "creating Excel/ZIP file <%s>",
        MSG012 = "creating Excel internal directory structure",
        MSG013 = "created file %s, size = %d bytes",
        MSG014 = "lines: %d read, records: %d read, %d written",
        MSG015 = "elapsed time = %s",
        MSG016 = "opening input file <%s>, size = %d bytes",
        MSG017 = "read rate = %.0f records per second",
        MSG018 = "line# <%d>, record name <%s> not found, %d first bytes of the line=<%s>",
        MSG019 = "creating output file <%s>",
        MSG020 = "conversion error, line# <%d>, record <%s>, field <%s> value <%s> to type <%s>, resetting to NULL",
        MSG021 = "creating tables, SQL pool size = %d",
        MSG022 = "%d table(s) created",
        MSG023 = "layout <%s> read, %d record(s) created",
        MSG024 = "record filter error: field <%s> is not found in layout",
        MSG025 = "creating table (for record) <%s>",
        MSG026 = "field filter requested, layout has now <%d> records",
        MSG027 = "====> configuration file is <%s>",
        MSG028 = "built SQL statement: <%s>",
        MSG029 = "error: sqlite3_prepare_v2() API error, SQL error %d, statement=<%s>, error msg <%s>",
        MSG030 = "error: operator <%s> not supported. Admissible operator list is %s",
        MSG031 = "error: converting value %s to type %s",
        MSG032 = "error: element name %s already in container",
        MSG033 = "error: index %d is out of bounds for _list[]",
        MSG034 = "record %s is not matching declared length (%d instead of %d)",
        MSG035 = "layout %s validates!!",
        MSG036 = "error: unknown mapper lambda <%d> in layout <%s>",
        MSG037 = "error: XML definition file <%s> not found",
        MSG038 = "error: mapper function is not defined in layout",
        MSG039 = "option break records requested",
        MSG040 = "record <%s>, repeated pattern <%s>",
        MSG041 = "error: field filter file %s not found",
        MSG042 = "error: record filter file %s not found",
        MSG043 = "error: unknown output mode. Should be in the following list: %s",
        MSG044 = "error: break record options is only compatible with txt/box output formats",
        MSG045 = "zip command failed, rc = <%d>",
        MSG046 = "error: INSERT statement, error code = <%d>, error msg <%s>",
        MSG047 = "error: database create error: <%s>",
        MSG048 = "error: SQL error %d when opening file %d, SQL msg %s",
        MSG049 = "worksheet name = <%s>",
        MSG050 = "starting conversion, nbCpus = %d",
        MSG051 = "error: input file <%s> not found",
        MSG052 = "sqlite3 lib version <%s>",
        MSG053 = "number of bad formatted fields: <%d>",
        MSG054 = "error: field %s is not in layout %s",
        MSG055 = "field filter error: record <%s> is not found in layout",
        MSG056 = "new field type: name=<%s>, type=<%s>, pattern=<%s>, format=<%s>",
        MSG057 = "processing record-based file creation",
        MSG058 = "fatal: output format should be in the following list: %s",
        MSG059 = "add zip archive <%s>",
        MSG060 = "deleting unnecessary files",
        MSG061 = "started with the following arguments: %s",
        MSG062 = "fatal error: type <%s> is not defined for field <%s> !!",
        MSG063 = "error: statement <%s>, error code = <%d>, error msg <%s>",
        MSG064 = "error: sqlite_bind() API error, error code = <%d>, error msg <%s>",
        MSG065 = "%d lines processed so far",
        MSG066 = "%d/%d records processed so far (%.0f percent), %d matching record filter condition\r",
        MSG067 = "reading configuration file <%s> from environment variable <%s>",
        MSG068 = "creating/using default log file <%s>",
        MSG069 = "reading configuration file <%s> from the current directory",
        MSG070 = "reading configuration file <%s> from the default location",
        MSG071 = "reading configuration file <%s> from the command line",
        MSG072 = "%s table is populated",
        MSG073 = "error: SQL statement file <%s> not found",
        MSG074 = "reading external SQL statement file <%s>",
        MSG075 = "triggering pre-sql file <%s>",
        MSG076 = "triggering post-sql file <%s>",
        MSG077 = "field filter requested, keeping only <%s>",
        MSG078 = "error: template file <%s> not found",
        MSG079 = "error: element name <%s> is not in unique list of record/container <%s>",
        MSG080 = "using template file <%s>",
        MSG081 = "error: record name is empty",
        MSG082 = "error: no name attribute when creating record",
        MSG083 = "error: no description attribute when creating record",
        MSG084 = "error: no name attribute when creating field",
        MSG085 = "error: no description attribute when creating field",
        MSG086 = "error: no length attribute when creating field",
        MSG087 = "error: no type attribute when creating field",
        MSG088 = "error: XMl configuration file <%s> not found",
        MSG089 = "error: input file <%s> for XML file creation not found",
        MSG090 = "error: unknown sanitizing option for tag <%s> and attribute <%s>",
        MSG091 = "error: no template file provided",
        MSG092 = "PostgreSQL lib version <%d>, connection string = <%s>",
        MSG093 = "error: PostgreSQL error <%d> when opening db <%s>, SQL msg <%s>",
        MSG094 = "error: PostgreSQL exec error <%d>, stmt=<%s>, SQL msg <%s>",
        MSG095 = "creating tables, SQL transaction pool size = %d, SQL insert pool size = %d",
        MSG096 = "record <%s> count: <%d>",
        MSG097 = "message index <%s> is not found",
}

auto build_msg(Message, A...)(Message m, A args)
{
    // build message
    auto msg = m.format(args);
    return "%s - %s".format(to!string(m), msg);
}

// new Exception class to handle rbf errors
class RbfException : Exception
{
    public:
        Message m;

        this(Message, A...)(Message msg, A args)
        {
            m = to!Message(msg);
            auto message = build_msg(m, args);
            super(message, __FILE__, __LINE__, next);
        }
}

