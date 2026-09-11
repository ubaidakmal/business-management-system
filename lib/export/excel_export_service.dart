import 'dart:typed_data';

import 'package:excel/excel.dart';

import 'report_export_data.dart';

abstract final class ExcelExportService {
  static Uint8List build(ReportExportData data) {
    final excel = Excel.createExcel();
    final defaultName = excel.getDefaultSheet();
    final sheetName = _sheetName(data.title);
    if (defaultName != null) {
      excel.rename(defaultName, sheetName);
    }
    final sheet = excel[sheetName];

    var rowIndex = 0;
    void writeText(int column, String value, {bool bold = false}) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: rowIndex),
      );
      cell.value = TextCellValue(value);
      if (bold) cell.cellStyle = CellStyle(bold: true);
    }

    writeText(0, data.businessName, bold: true);
    rowIndex++;
    writeText(0, data.title, bold: true);
    rowIndex++;
    writeText(0, 'Generated: ${data.generatedAtLabel}');
    rowIndex++;
    if (data.filters.isNotEmpty) {
      writeText(0, 'Filters: ${data.filters.join(' · ')}');
      rowIndex++;
    }

    rowIndex++;
    writeText(0, 'Summary', bold: true);
    rowIndex++;
    for (final metric in data.summary) {
      writeText(0, metric.label);
      writeText(1, metric.value);
      rowIndex++;
    }

    rowIndex++;
    for (var c = 0; c < data.columns.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex),
      );
      cell.value = TextCellValue(data.columns[c]);
      cell.cellStyle = CellStyle(bold: true);
    }
    rowIndex++;

    for (final row in data.rows) {
      for (var c = 0; c < row.length; c++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          row[c],
        );
      }
      rowIndex++;
    }

    final colCount = data.columns.isEmpty ? 1 : data.columns.length;
    final widths = List<double>.filled(colCount, 12);
    for (var c = 0; c < data.columns.length; c++) {
      widths[c] = (data.columns[c].length + 2).clamp(10, 40).toDouble();
    }
    for (final row in data.rows) {
      for (var c = 0; c < row.length && c < widths.length; c++) {
        final len = (row[c].length + 2).clamp(10, 40).toDouble();
        if (len > widths[c]) widths[c] = len;
      }
    }
    for (var c = 0; c < widths.length; c++) {
      sheet.setColumnWidth(c, widths[c]);
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('Failed to encode Excel workbook.');
    }
    return Uint8List.fromList(encoded);
  }

  static String _sheetName(String title) {
    final cleaned = title.replaceAll(RegExp(r'[\\/*?:\[\]]'), ' ').trim();
    if (cleaned.isEmpty) return 'Report';
    return cleaned.length > 31 ? cleaned.substring(0, 31) : cleaned;
  }
}
