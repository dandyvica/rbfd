// D import file generated from 'source\rbf\writers\writer.d'
module rbf.writers.writer;
pragma (msg, "========> Compiling module ", "rbf.writers.writer");
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;
import rbf.errormsg;
import rbf.log;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.config;
import rbf.writers.csvwriter;
import rbf.writers.txtwriter;
import rbf.writers.boxwriter;
import rbf.writers.htmlwriter;
import rbf.writers.tagwriter;
import rbf.writers.identwriter;
import rbf.writers.sqlite3writer;
import rbf.writers.xmlwriter;
import rbf.writers.xlsx1writer;
import rbf.writers.xlsx2writer;
enum OutputFormat 
{
	box,
	csv,
	html,
	ident,
	sql,
	tag,
	txt,
	excel1,
	excel2,
	xml,
}
abstract class Writer
{
	private 
	{
		string _outputFileName;
		package 
		{
			File _fh;
			string _previousRecordName;
			public 
			{
				OutputFeature outputFeature;
				this(in string outputFileName, in bool create = true)
				{
					_outputFileName = outputFileName;
					if (outputFileName != "")
					{
						_outputFileName = outputFileName;
						if (create)
						{
							_fh = File(_outputFileName, "w");
							log.log(LogLevel.INFO, MSG019, outputFileName);
						}
					}
					else
						_fh = stdout;
				}
				abstract void prepare(Layout layout);
				abstract void build(string outputFileName);
				abstract void write(Record rec);
				void open()
				{
					_fh = File(_outputFileName, "w");
				}
				void close()
				{
					if (_outputFileName != "")
						_fh.close();
				}
			}
		}
	}
}
Writer writerFactory(in string output, in OutputFormat fmt)
{
	final switch (fmt)
	{
		case OutputFormat.box:
		{
			return new BoxWriter(output);
		}
		case OutputFormat.csv:
		{
			return new CSVWriter(output);
		}
		case OutputFormat.html:
		{
			return new HTMLWriter(output);
		}
		case OutputFormat.ident:
		{
			return new IdentWriter(output);
		}
		case OutputFormat.sql:
		{
			return new Sqlite3Writer(output);
		}
		case OutputFormat.tag:
		{
			return new TAGWriter(output);
		}
		case OutputFormat.txt:
		{
			return new TXTWriter(output);
		}
		case OutputFormat.excel1:
		{
			return new XLSX1Writer(output);
		}
		case OutputFormat.excel2:
		{
			return new XLSX2Writer(output);
		}
		case OutputFormat.xml:
		{
			return new XmlWriter(output);
		}
	}
}
