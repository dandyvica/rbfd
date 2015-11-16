module rbf.errormsg;

import std.stdio;
import std.file;
import std.string;
import std.conv;
import std.algorithm;
import std.range;
import std.datetime;

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
immutable MSG015 = "info: elapsed time = %s";
immutable MSG016 = "opening input file <%s>, size = %d bytes";
immutable MSG017 = "read rate = %.0f records per second";
immutable MSG018 = "line# <%d>, record name <%s> not found";
immutable MSG019 = "creating output file <%s>";
immutable MSG020 = "conversion error, value <%s> to type <%s>, resetting to NULL";
immutable MSG021 = "creating tables, SQL pool size = %d";
immutable MSG022 = "%d tables created";
immutable MSG023 = "layout <%s> read, %d records created";
immutable MSG024 = "record filter error: field <%s> is not found in layout";

Log log;

enum LogLevel { INFO, WARNING, ERROR, FATAL }

struct Log 
{
private:
    File _logHandle;

public:
    this(string logFileName)
    {
        _logHandle = File(logFileName, "a");
    }

    void log(LogLevel, string, A...)(LogLevel level, string msg, A args)
    {
        auto now = to!DateTime(Clock.currTime);
        _logHandle.writef("%s - %s ", now, to!string(level));
        _logHandle.writefln(msg, args);
        _logHandle.flush;
    }


    ~this() 
    {
        _logHandle.close;
    }
}

