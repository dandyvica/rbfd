module rbf.log;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.algorithm;
import std.conv;
import std.datetime;
import std.exception;
import std.file;
import std.process;
import std.range;
import std.stdio;
import std.string;

import rbf.errormsg;

// global log variable
Log log, logerr;

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

    // log with flexible list of arguments
    void _log(LogLevel, string, A...)(LogLevel level, string index, string msg, A args)
    {
        if (level != LogLevel.TRACE || _trace != "")
        {
            // don't write out log header when console output
            if (_logHandle != stdout && _logHandle != stderr)
            {
                _logHandle.writef("%-28.28s - [%s - %s] - ", to!string(Clock.currTime), to!string(level), index);
            }
            // just output message index and text
            else
            {
                _logHandle.writef("%s - ", index);
            }
            _logHandle.writefln(msg, args);
            _logHandle.flush;
        }
    }


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
            logerr.info("MSG068", defaultLogFile);
        }
        _trace = environment.get("RBF_TRACE", "");
    }

    // another ctor if we want to output elsewhere
    this(File fh)
    {
        _logHandle = fh;
    }

    // useful helpers
    void trace(string, A...)(string message_index, A args)   { _log(LogLevel.TRACE, message_index, errorMessageList.error_msg[message_index], args); }
    void info(string, A...)(string message_index, A args)    { _log(LogLevel.INFO, message_index, errorMessageList[message_index], args); }
    void warning(string, A...)(string message_index, A args) { _log(LogLevel.WARNING, message_index, errorMessageList.error_msg[message_index], args); }
    void error(string, A...)(string message_index, A args)   { _log(LogLevel.ERROR, message_index, errorMessageList.error_msg[message_index], args); }
    void fatal(string, A...)(string message_index, A args)   { _log(LogLevel.FATAL, message_index, errorMessageList.error_msg[message_index], args); }

    // special use for enforcing conditions
    static auto build_msg(string, A...)(string message_index, A args)
    {
        // build message
        auto msg = errorMessageList.error_msg[message_index].format(args);
        return "%s: %s".format(message_index, msg);
    }

    // close log file
    ~this() 
    {
        _logHandle.close;
    }
}

