module rbf.log;

import std.stdio;
import std.file;
import std.string;
import std.conv;
import std.algorithm;
import std.range;
import std.datetime;
import std.process;

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

    // create log file
    this(string logFileName)
    {
        _logHandle = File(logFileName, "a");
        _trace = environment.get("RBF_TRACE", "");
    }

    // log with flexible list of arguments
    void log(LogLevel, string, A...)(LogLevel level, string msg, A args)
    {
        if (level != LogLevel.TRACE || _trace != "")
        {
            _logHandle.writef("%s - [%s] - ", Clock.currTime, to!string(level));
            _logHandle.writefln(msg, args);
            _logHandle.flush;
        }
    }

    void info(string, A...)(string msg, A args) { log(LogLevel.info, msg, args); }

    // close log file
    ~this() 
    {
        _logHandle.close;
    }
}

