// D import file generated from 'source/rbf/writers/writer.d'
module rbf.writers.writer;
pragma (msg, "========> Compiling module ", "rbf.writers.writer");
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.variant;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.config;
import rbf.writers.xlsxwriter;
import rbf.writers.csvwriter;
import rbf.writers.txtwriter;
import rbf.writers.boxwriter;
import rbf.writers.htmlwriter;
import rbf.writers.tagwriter;
import rbf.writers.identwriter;
import rbf.writers.latexwriter;
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
							_fh = File(_outputFileName, "w");
					}
					else
						_fh = stdout;
				}
				abstract void prepare();
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
Writer writerFactory(in string output, in string mode, Layout layout)
{
	switch (mode)
	{
		case "html":
		{
			return new HTMLWriter(output);
		}
		case "csv":
		{
			return new CSVWriter(output);
		}
		case "txt":
		{
			return new TXTWriter(output);
		}
		case "box":
		{
			return new BoxWriter(output);
		}
		case "xlsx":
		{
			return new XLSXWriter(output, layout);
		}
		case "sql":
		{
			return new TXTWriter(output);
		}
		case "tag":
		{
			return new TAGWriter(output);
		}
		case "latex":
		{
			return new LatexWriter(output);
		}
		case "ident":
		{
			return new IdentWriter(output);
		}
		default:
		{
			throw new Exception("error: writer unknown mode <%s>".format(mode));
		}
	}
}
