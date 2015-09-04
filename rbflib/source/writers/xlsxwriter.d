module rbf.writers.xlsxwriter;

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.array;
import std.zip;
//import std.time;

import rbf.field;
import rbf.record;
import rbf.writers.writer;
import rbf.conf;

/**
 * define the type of XML for OpenXML depending on value
 */
enum XlsxRowType : string
{
	XLSX_STRROW = `<c t="inlineStr"><is><t>%s</t></is></c>`,
	XLSX_NUMROW = "<c><v>%s</v></c>"
}
/**
 * used to build the aa for creating XLSX file/dir structure
 */
struct XLSXPattern {
	string fileName;
	string fileString;
	string fileTag;
	string constructedTags = "";
}


class XLSXWriter : Writer {
private:

	string _xlsxFilename;		/// Excel worksheet file name
	string _xlsxDir;				/// directory used to gather all Excel files
	string[] _worksheets;   /// list of worksheets for the Excel file

	static XLSXPattern[string] pattern;

	// convert a string value to an Excel XML cell
	string _toXLSXRow(string value, FieldType ft = FieldType.ALPHABETICAL)
	{
		// depending on its type, an Excel cell doesn't contain the same XML
		if (ft == FieldType.ALPHABETICAL || ft == FieldType.ALPHANUMERICAL)
		{
			return XlsxRowType.XLSX_STRROW.format(value);
		}
		else
		{
			return XlsxRowType.XLSX_NUMROW.format(value);
		}
	}

	// create the zip archive as an XLSX file
	void _create_zip() {
		// ch dir to XLSX directory
		chdir(_xlsxDir);

		// create zip
		auto result = std.process.execute([configSettings.zipper, "-r", "../" ~ _xlsxFilename, "."]);
		if (result.status != 0)
			throw new Exception("zip command failed:\n", result.output);

		// now it's sace to remove all files
		chdir("..");
		rmdirRecurse(_xlsxDir);
	}

public:

	this(string outputFileName)
	{

		super(outputFileName);

		pattern["workbook"] =
			XLSXPattern("workbook.xml", import("workbook.xml"),
									`<sheet name="%s" sheetId="%d" r:id="rId%d"/>`);

		pattern["content_types"] =
			XLSXPattern("[Content_Types].xml", import("[Content_Types].xml"),
									`<Override PartName="/%s.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>\n`);

		pattern["rels"] =
			XLSXPattern("_rels/.rels", import("rels.xml"), "");

		pattern["workbook_rels"] =
			XLSXPattern("_rels/workbook.xml.rels", import("workbook.xml.rels"),
								   `<Relationship Id="rId%d" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="%s.xml"/>\n`);

		pattern["worksheet"] =
			XLSXPattern("worksheet.xml", import("worksheet.xml"), "");



		// save file name
		_xlsxFilename = std.path.baseName(outputFileName);

		// create a unique XLSX directory structure
		_xlsxDir = "./%s.%d".format(_xlsxFilename, std.datetime.Clock.currStdTime());
		mkdir(_xlsxDir);
		mkdir(_xlsxDir ~ "/_rels");
	}

	override void write(Record record)
	{
		auto worksheetFilename = _xlsxDir ~ "/" ~ record.name ~ ".xml";
		File worksheetHandle;

		if (!exists(worksheetFilename))
		{
			// create file
			worksheetHandle = File(worksheetFilename, "w");
			worksheetHandle.write(pattern["worksheet"].fileString);

			// write worksheet column description
			worksheetHandle.write("<row>");
			foreach (Field f; record)
			{
				worksheetHandle.write(_toXLSXRow(f.description));
			}
			worksheetHandle.write("</row>");

			// write worksheet column name
			worksheetHandle.write("<row>");
			foreach (Field f; record)
			{
				worksheetHandle.write(_toXLSXRow(f.name));
			}
			worksheetHandle.write("</row>");

			// add record to list of records
			_worksheets ~= record.name;
		}
		else
			// just append if already exists
			worksheetHandle = File(worksheetFilename, "a");

		// start writing cells
		worksheetHandle.write("<row>");
		foreach (Field f; record)
		{
			worksheetHandle.write(_toXLSXRow(f.value, f.type));
		}
		worksheetHandle.write("</row>");
	}

	override void close()
	{
		ushort i=0;

		foreach (string worksheetName; sort(_worksheets))
		{
			//writeln(worksheetName);
			pattern["workbook"].constructedTags ~= pattern["workbook"].fileTag.format(worksheetName, i+1, i+1);
			pattern["workbook_rels"] .constructedTags ~= pattern["workbook_rels"].fileTag.format(i+1, worksheetName);
			pattern["content_types"].constructedTags ~=  pattern["content_types"].fileTag.format(worksheetName);
			i++;
		}

		foreach (string name, XLSXPattern xlsxTag; pattern)
		{
			if (name != "worksheet")
				std.file.write(_xlsxDir ~ "/" ~ xlsxTag.fileName, xlsxTag.fileString.replace("<tags>", xlsxTag.constructedTags));
		}

		// at the end, complete worksheet XML files
		foreach (string worksheetName; _worksheets)
		{
			auto fh = File(_xlsxDir ~ "/" ~ worksheetName ~ ".xml","a");
			fh.write("</sheetData></worksheet>");
			fh.close();
		}

		// finally create zip
		_create_zip();
	}


}
