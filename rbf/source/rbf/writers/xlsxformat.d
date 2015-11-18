module rbf.writers.xlsxformat;
pragma(msg, "========> Compiling module ", __MODULE__);

import std.stdio;
import std.file;
import std.string;
import std.exception;
import std.algorithm;
import std.array;
import std.zip;

import rbf.field;

class XlsxEntity {
private:

  File _fh;
  string _fileName;

public:

  this (string fileName) {
    _fileName = fileName;

    _fh = File(_fileName, "w");
    _fh.writeln(`<?xml version="1.0" encoding="UTF-8" standalone="yes"?>`);
  }

  void close() { _fh.close; }

}


class ContentTypes : XlsxEntity {

  this(string path) {

    super(path ~ "/[Content_Types].xml");

    _fh.writeln(`<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">`);
    _fh.writeln(`<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>`);
    _fh.writeln(`<Default Extension="xml" ContentType="application/xml"/>`);
    _fh.writeln(`<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>`);

  }

  void fill(string worksheetName) {
    _fh.writefln(`<Override PartName="/xl/worksheets/%s.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>`, worksheetName);
  }

  override void close() {
    _fh.writeln("</Types>");
    XlsxEntity.close;
  }

}


class Workbook : XlsxEntity {
private:

  ushort sheetIndex;

public:

  this(string path) {
    super(path ~ "/xl/workbook.xml");
    _fh.writeln(`<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">`);
    _fh.writeln("<sheets>");
  }

  void fill(string worksheetName) {
    _fh.writefln(`<sheet name="%s" sheetId="%d" r:id="rId%d"/>`, worksheetName, ++sheetIndex, sheetIndex);
  }

  override void close() {
    _fh.writeln("</sheets></workbook>");
    XlsxEntity.close;
  }

}


class Worksheet : XlsxEntity {

  this(string path, string worksheetName) {
    super(path ~ "/xl/worksheets/" ~ worksheetName ~ ".xml");
    _fh.writeln(`<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x14ac" xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac">`);
    _fh.writeln("<sheetData>");
  }

  void startRow() { _fh.write("<row>"); }
  void endRow() { _fh.writeln("</row>"); }

  void strCell(T)(T cellValue) {
    _fh.writefln(`<c t="inlineStr"><is><t>%s</t></is></c>`, cellValue);
  }

  void numCell(TVALUE cellValue) {
    _fh.writefln(`<c><v>%s</v></c>`, cellValue);
  }

  override void close() {
    _fh.writeln("</sheetData></worksheet>");
    XlsxEntity.close;
  }

}


class Rels : XlsxEntity {

  this(string path) {
    super(path ~ "/_rels/.rels");
    _fh.writeln(`<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">`);
    _fh.writeln(`<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>`);
    _fh.writeln(`</Relationships>`);
  }

  void fill(string worksheetName) {
    _fh.writefln(`<Relationship Id="rId%d" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/%s.xml"/>`);
  }

  override void close() {
    XlsxEntity.close;
  }

}


class WorkbookRels : XlsxEntity {

private:
  ushort sheetIndex;

public:

  this(string path) {
    super(path ~ "/xl/_rels/workbook.xml.rels");
    _fh.writeln(`<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">`);
  }

  void fill(string worksheetName) {
    _fh.writefln(`<Relationship Id="rId%d" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/%s.xml"/>`, ++sheetIndex, worksheetName);
  }

  override void close() {
    _fh.writeln("</Relationships>");
    XlsxEntity.close;
  }

}
