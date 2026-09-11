import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'report_export_data.dart';

abstract final class PdfExportService {
  static Future<Uint8List> build(ReportExportData data) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _header(data),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                data.businessName,
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 8),
          _summary(data),
          pw.SizedBox(height: 16),
          _table(data),
          if (data.rows.isEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Text(
                'No rows for the selected filters.',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(ReportExportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          data.businessName,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          data.title,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated: ${data.generatedAtLabel}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        if (data.filters.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            'Filters: ${data.filters.join(' · ')}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey400),
      ],
    );
  }

  static pw.Widget _summary(ReportExportData data) {
    if (data.summary.isEmpty) return pw.SizedBox();
    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final metric in data.summary)
          pw.Container(
            width: 140,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  metric.label,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  metric.value,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _table(ReportExportData data) {
    final headers = data.columns;
    final columnCount = headers.isEmpty ? 1 : headers.length;

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data.rows,
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
      columnWidths: {
        for (var i = 0; i < columnCount; i++) i: const pw.FlexColumnWidth(),
      },
    );
  }
}
