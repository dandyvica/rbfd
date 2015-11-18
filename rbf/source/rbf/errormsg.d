module rbf.errormsg;

import std.stdio;
import std.file;
import std.string;
import std.conv;
import std.algorithm;
import std.range;
import std.datetime;
import std.process;

// list of all error messages found in code
immutable MSG001 = "error: element name %s is not in container %s";
immutable MSG002 = "line# <%d>, record <%s>, field <%s>, value <%s> is not matching expected pattern <%s>";
immutable MSG003 = "name=<%s>, description=<%s>, length=<%u>, type=<%s>, lower/upperBound=<%u:%u>, rawValue=<%s>, value=<%s>, offset=<%s>, index=<%s>";
immutable MSG004 = "error: settings file <%s> not found";
immutable MSG005 = "error: element %s, index %d is out of bounds";
immutable MSG006 = "error: cannot call get method with index %d without allowing duplicated";
immutable MSG007 = "error: lower index %d is out of bounds, upper bound = %d";
immutable MSG008 = "error: upper index %d is out of bounds, upper bound = %d";
immutable MSG009 = "error: lower index %d is higher than upper index %d";
immutable MSG010 = "error: unable to create field, wrong number of csv data (%d, expected %d)";
immutable MSG011 = "info: creating Excel file";
immutable MSG012 = "info: creating Excel internal directory structure";
immutable MSG013 = "\ninfo: created file %s, size = %d bytes";
immutable MSG014 = "info: lines: %d read, records: %d read, %d written";
immutable MSG015 = "elapsed time = %s";
immutable MSG016 = "opening input file <%s>, size = %d bytes";
immutable MSG017 = "read rate = %.0f records per second";
immutable MSG018 = "line# <%d>, record name <%s> not found";
immutable MSG019 = "creating output file <%s>";
immutable MSG020 = "conversion error, value <%s> to type <%s>, resetting to NULL";
immutable MSG021 = "creating tables, SQL pool size = %d";
immutable MSG022 = "%d table(s) created";
immutable MSG023 = "layout <%s> read, %d record(s) created";
immutable MSG024 = "record filter error: field <%s> is not found in layout";
immutable MSG025 = "creating table for record <%s>";
immutable MSG026 = "field filter requested, layout has now <%d> records";
immutable MSG027 = "configuration file is <%s>";
immutable MSG028 = "built SQL statement: <%s>";
immutable MSG029 = "error: sqlite3_prepare_v2() API error, SQL error %d, statement=<%s>, error msg <%s>";
immutable MSG030 = "error: operator %s not supported";
immutable MSG031 = "error: converting value %s %s %s to type %s";
immutable MSG032 = "error: element name %s already in container";
immutable MSG033 = "error: index %d is out of bounds for _list[]";
immutable MSG034 = "record %s is not matching declared length (%d instead of %d)";
immutable MSG035 = "layout %s validates!!";
immutable MSG036 = "error: unknown mapper lambda <%d> in layout <%s>";
immutable MSG037 = "error: XML definition file <%s> not found";
immutable MSG038 = "error: mapper function is not defined in layout";

// global log variable
Log log;

// list of all possible values for log level
// TRACE is enabled by setting the RBF_TRACE variable
enum LogLevel { TRACE, INFO, WARNING, ERROR, FATAL }

// simple log feature
struct Log 
{
private:
    File _logHandle;
    string _trace;

public:
    this(string logFileName)
    {
        _logHandle = File(logFileName, "a");
        _trace = environment.get("RBF_TRACE", "");
    }

    void log(LogLevel, string, A...)(LogLevel level, string msg, A args)
    {
        auto now = to!DateTime(Clock.currTime);
        if (level != LogLevel.TRACE || _trace != "")
        {
            _logHandle.writef("%s - %s ", now, to!string(level));
            _logHandle.writefln(msg, args);
            _logHandle.flush;
        }
    }


    ~this() 
    {
        _logHandle.close;
    }
}

