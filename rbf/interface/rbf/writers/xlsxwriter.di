// D import file generated from 'source/rbf/writers/xlsxwriter.d'
module rbf.writers.xlsxwriter;
pragma (msg, "========> Compiling module ", "rbf.writers.xlsxwriter");
import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.array;
import std.zip;
import std.conv;
import std.xml;
import rbf.errormsg;
import rbf.log;
import rbf.fieldtype;
import rbf.field;
import rbf.record;
import rbf.layout;
import rbf.writers.writer;
import rbf.writers.xlsxformat;
class XLSXWriter : Writer
{
	package 
	{
		string _xlsxFilename;
		string _xlsxDir;
		ContentTypes _contentTypesFile;
		Workbook _workbookFile;
		Rels _relsFile;
		WorkbookRels _workbookRelsFile;
		void _buildZip()
		{
			ArchiveMember _addArchive(string fileName)
			{
				ArchiveMember am = new ArchiveMember;
				am.name = fileName;
				am.expandedData(cast(ubyte[])std.file.read(fileName));
				return am;
			}
			ZipArchive zip = new ZipArchive;
			chdir(_xlsxDir);
			zip.addMember(_addArchive("_rels/.rels"));
			zip.addMember(_addArchive("xl/_rels/workbook.xml.rels"));
			zip.addMember(_addArchive("xl/workbook.xml"));
			zip.addMember(_addArchive("[Content_Types].xml"));
			auto entries = dirEntries("xl/worksheets", "*.xml", SpanMode.shallow);
			foreach (f; entries)
			{
				log.log(LogLevel.INFO, MSG059, f.name);
				zip.addMember(_addArchive(f.name));
			}
			void[] compressedData = zip.build();
			chdir("..");
			std.file.write(_xlsxFilename, compressedData);
			log.log(LogLevel.INFO, MSG011, _xlsxFilename);
			log.log(LogLevel.INFO, MSG060);
			rmdirRecurse(_xlsxDir);
		}
		void _writeRecordToWorksheet(Record record, Worksheet worksheetFile)
		{
			worksheetFile.startRow();
			foreach (field; record)
			{
				if (field.type.meta.stringType == "string")
				{
					worksheetFile.strCell!TVALUE(field.value.encode);
				}
				else
				{
					worksheetFile.numCell(field.value.encode);
				}
			}
			worksheetFile.endRow();
		}
		public 
		{
			this(string excelFileName)
			{
				super(excelFileName, false);
				log.log(LogLevel.INFO, MSG012);
				_xlsxFilename = std.path.baseName(excelFileName);
				_xlsxDir = "./%s.%d".format(_xlsxFilename, std.datetime.Clock.currStdTime());
				mkdir(_xlsxDir);
				mkdir(_xlsxDir ~ "/_rels");
				mkdir(_xlsxDir ~ "/xl");
				mkdir(_xlsxDir ~ "/xl/_rels");
				mkdir(_xlsxDir ~ "/xl/worksheets");
				_contentTypesFile = new ContentTypes(_xlsxDir);
				_workbookFile = new Workbook(_xlsxDir);
				_workbookRelsFile = new WorkbookRels(_xlsxDir);
				_relsFile = new Rels(_xlsxDir);
			}
			override void prepare(Layout layout)
			{
			}
			override void close()
			{
				_contentTypesFile.close;
				_workbookFile.close;
				_workbookRelsFile.close;
				_relsFile.close;
				_buildZip();
			}
		}
	}
}
