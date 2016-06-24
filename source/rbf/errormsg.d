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
        MSG001 = "element name <%s> is not in record/container <%s>",
        MSG002 = "line# <%d>, record <%s>, field <%s>, value <%s> is not matching expected pattern <%s>",
        MSG003 = "name=<%s>, description=<%s>, length=<%u>, type=<%s>, lower/upperBound=<%u:%u>, rawValue=<%s>, value=<%s>, offset=<%s>, index=<%s>",
        MSG004 = "settings file <%s> not found",
        MSG005 = "element %s, index %d is out of bounds",
        MSG006 = "cannot call get method with index %d without allowing duplicated",
        MSG007 = "lower index %d is out of bounds, upper bound = %d",
        MSG008 = "upper index %d is out of bounds, upper bound = %d",
        MSG009 = "lower index %d is higher than upper index %d",
        MSG010 = "unable to create field, wrong number of csv data (%d, expected %d)",
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
        MSG024 = "record filter field <%s> is not found in layout",
        MSG025 = "creating table (for record) <%s>",
        MSG026 = "field filter requested, layout has now <%d> records",
        MSG027 = "====> configuration file is <%s>",
        MSG028 = "built SQL statement: <%s>",
        MSG029 = "sqlite3_prepare_v2() API error, SQL error %d, statement=<%s>, error msg <%s>",
        MSG030 = "operator <%s> not supported. Admissible operator list is %s",
        MSG031 = "converting value %s to type %s",
        MSG032 = "element name %s already in container",
        MSG033 = "index %d is out of bounds for _list[]",
        MSG034 = "record %s is not matching declared length (%d instead of %d)",
        MSG035 = "layout %s validates!!",
        MSG036 = "unknown mapper lambda <%d> in layout <%s>",
        MSG037 = "XML definition file <%s> not found",
        MSG038 = "mapper function is not defined in layout",
        MSG039 = "option break records requested",
        MSG040 = "record <%s>, repeated pattern <%s>",
        MSG041 = "field filter file %s not found",
        MSG042 = "record filter file %s not found",
        MSG043 = "unknown output mode. Should be in the following list: %s",
        MSG044 = "break record options is only compatible with txt/box output formats",
        MSG045 = "zip command failed, rc = <%d>",
        MSG046 = "INSERT statement, error code = <%d>, error msg <%s>",
        MSG047 = "database create <%s>",
        MSG048 = "SQL error %d when opening file %d, SQL msg %s",
        MSG049 = "worksheet name = <%s>",
        MSG050 = "starting conversion, nbCpus = %d",
        MSG051 = "input file <%s> not found",
        MSG052 = "sqlite3 lib version <%s>",
        MSG053 = "number of bad formatted fields: <%d>",
        MSG054 = "field %s is not in layout %s",
        MSG055 = "field filter record <%s> is not found in layout",
        MSG056 = "new field type: name=<%s>, type=<%s>, pattern=<%s>, format=<%s>",
        MSG057 = "processing record-based file creation",
        MSG058 = "output format should be in the following list: %s",
        MSG059 = "add zip archive <%s>",
        MSG060 = "deleting unnecessary files",
        MSG061 = "started with the following arguments: %s",
        MSG062 = "fatal type <%s> is not defined for field <%s> !!",
        MSG063 = "statement <%s>, error code = <%d>, error msg <%s>",
        MSG064 = "sqlite_bind() API error, error code = <%d>, error msg <%s>",
        MSG065 = "%d lines processed so far\r",
        MSG066 = "%d/%d records processed so far (%.0f percent), %d matching record filter condition\r",
        MSG067 = "reading configuration file <%s> from environment variable <%s>",
        MSG068 = "creating/using default log file <%s>",
        MSG069 = "reading configuration file <%s> from the current directory",
        MSG070 = "reading configuration file <%s> from the default location",
        MSG071 = "reading configuration file <%s> from the command line",
        MSG072 = "%s table is populated",
        MSG073 = "SQL statement file <%s> not found",
        MSG074 = "reading external SQL statement file <%s>",
        MSG075 = "triggering pre-sql file <%s>",
        MSG076 = "triggering post-sql file <%s>",
        MSG077 = "field filter requested, keeping only <%s>",
        MSG078 = "template file <%s> not found",
        MSG079 = "element name <%s> is not in unique list of record/container <%s>",
        MSG080 = "using template file <%s>",
        MSG081 = "record name is empty",
        MSG082 = "no name attribute when creating record",
        MSG083 = "no description attribute when creating record",
        MSG084 = "no name attribute when creating field",
        MSG085 = "no description attribute when creating field",
        MSG086 = "no length attribute when creating field",
        MSG087 = "no type attribute when creating field",
        MSG088 = "XML configuration file <%s> not found",
        MSG089 = "configuration file <%s> for XML file creation not found",
        MSG090 = "unknown sanitizing option for tag <%s> and attribute <%s>",
        MSG091 = "no template file provided",
        MSG092 = "PostgreSQL lib version <%d>, connection string = <%s>",
        MSG093 = "PostgreSQL error <%d> when opening db <%s>, SQL msg <%s>",
        MSG094 = "PostgreSQL exec error <%d>, stmt=<%s>, SQL msg <%s>",
        MSG095 = "creating tables, SQL transaction pool size = %d, SQL insert pool size = %d",
        MSG096 = "record <%s> count: <%d>",
        MSG097 = "message index <%s> is not found",
        MSG098 = "%s - file <%s(%d)>",
        MSG099 = "%-10.10s\t%-60.60s\t%s",
        MSG100 = "unknown argument %s",
}

// new Exception class to handle rbf errors
@disable class RbfException : Exception
{
    public:

        this(string message, string file=__FILE__, size_t line=__LINE__, Throwable next=null)
        {
            super(message, file, line, next);
        }
}

