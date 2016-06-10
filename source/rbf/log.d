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
enum defaultLogFile = "rbf.log";
enum defaultHeaderFormat = "%-28.28s - %s - ";

// list of all possible values for log level
// TRACE is enabled by setting the RBF_TRACE variable
enum LogLevel { TRACE, INFO, WARNING, ERROR, FATAL }

// simple log feature
struct Log 
{
private:
    File _logHandle;            // handle on log file
    string _trace;              // to enable trace, need to define RBF_LOG environment variable

    // build header of each line in the log
    auto _header(LogLevel level)
    {
        return defaultHeaderFormat.format(to!string(Clock.currTime),  to!string(level));
    }

    // core logger
    void _log_core(LogLevel level, string msg)
    {
        if (level != LogLevel.TRACE || _trace != "")
        {
            // don't write out log header when console output
            if (_logHandle != stdout && _logHandle != stderr)
            {
                _logHandle.writef(_header(level));
            }
            //_logHandle.writefln(m.format(args));
            _logHandle.writefln(msg);
            _logHandle.flush;
        }
    }

    // write message in the log
    void _log_msg(LogLevel, Message, A...)(LogLevel level, Message m, A args)
    {
        _log_core(level, build_msg(m, args));
    }

    void _log_msg(LogLevel level, string msg)
    {
        _log_core(level, msg);
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
            logerr.info(Message.MSG068, defaultLogFile);
        }
        _trace = environment.get("RBF_TRACE", "");
    }

    // another ctor if we want to output elsewhere
    this(File fh)
    {
        _logHandle = fh;
    }

    // useful helpers
    void trace(Message, A...)(Message m, A args)   { _log_msg(LogLevel.TRACE, m, args); }
    void info(Message, A...)(Message m, A args)    { _log_msg(LogLevel.INFO, m, args); }
    void warning(Message, A...)(Message m, A args) { _log_msg(LogLevel.WARNING, m, args); }
    void error(Message, A...)(Message m, A args)   { _log_msg(LogLevel.ERROR, m, args); }
    void fatal(Message, A...)(Message m, A args)   { _log_msg(LogLevel.FATAL, m, args); }

    void exception(Exception e)
    {
        auto message = Message.MSG098.format(e.msg, e.file, e.line);
        _log_msg(LogLevel.FATAL, message);
    }

    // special use for enforcing conditions
    static auto build_msg(Message, A...)(Message m, A args)
    {
        // build message
        auto msg = m.format(args);
        return "%s - %s".format(to!string(m), msg);
    }

    // close log file
    ~this() 
    {
        _logHandle.close;
    }
}

