module rbf.log;

import std.stdio;
import std.file;
import std.string;
import std.conv;
import std.algorithm;
import std.range;
import std.datetime;
import std.process;
import std.exception;

import rbf.errormsg;

// global log variable
Log log;

// log file name if not possible to get it from configuration or not possible to open
// the location
immutable defaultLogFile = "rbf.log";

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

    // create log file
    this(string logFileName)
    {
        try
        {
            _logHandle = File(logFileName, "a");
        }
        catch (ErrnoException)
        {
            _logHandle = File(defaultLogFile, "a");
            writefln(MSG068, defaultLogFile);
        }
        _trace = environment.get("RBF_TRACE", "");
    }

    // log with flexible list of arguments
    void log(LogLevel, string, A...)(LogLevel level, string msg, A args)
    {
        if (level != LogLevel.TRACE || _trace != "")
        {
            _logHandle.writef("%-28.28s - [%s] - ", to!string(Clock.currTime), to!string(level));
            _logHandle.writefln(msg, args);
            _logHandle.flush;
        }
    }

    // useful helper
    void info(string, A...)(string msg, A args) { log(LogLevel.INFO, msg, args); }

    // close log file
    ~this() 
    {
        _logHandle.close;
    }
}

