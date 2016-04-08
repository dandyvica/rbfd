module rbf.log;
pragma(msg, "========> Compiling module ", __MODULE__);

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
    File _logHandle;            // handle on log file
    string _trace;              // to enable trace, need to define RBF_LOG environment variable

public:

    // create log file
    this(string logFileName)
    {
        try
        {
            // append to log file
            _logHandle = File(logFileName, "a");
        }
        catch (ErrnoException)
        {
            _logHandle = File(defaultLogFile, "a");
            writefln(MSG068, defaultLogFile);
        }
        _trace = environment.get("RBF_TRACE", "");
    }

    // another ctor if we want to output elsewhere
    this(File fh)
    {
        _logHandle = fh;
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

    // useful helpers
    void trace(string, A...)(string msg, A args) { log(LogLevel.TRACE, msg, args); }
    void info(string, A...)(string msg, A args) { log(LogLevel.INFO, msg, args); }
    void warning(string, A...)(string msg, A args) { log(LogLevel.WARNING, msg, args); }
    void error(string, A...)(string msg, A args) { log(LogLevel.ERROR, msg, args); }
    void fatal(string, A...)(string msg, A args) { log(LogLevel.FATAL, msg, args); }

    // close log file
    ~this() 
    {
        _logHandle.close;
    }
}

