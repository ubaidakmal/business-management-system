import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:business_management_app/export/excel_export_service.dart';
import 'package:business_management_app/export/pdf_export_service.dart';
import 'package:business_management_app/export/report_export_builders.dart';
import 'package:business_management_app/export/report_export_data.dart';
import 'package:business_management_app/l10n/app_localizations.dart';
import 'package:business_management_app/models/report.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('ReportExportBuilders.sales maps filtered summary and rows', () {
    final data = SalesReportData(
      summary: const SalesReportSummary(
        salesTotal: 100,
        salesCount: 1,
        totalCogs: 40,
        totalProfit: 60,
      ),
      rows: [
        SalesReportRow(
          id: 's1',
          invoiceNumber: 'INV-1',
          companyName: 'Acme',
          saleDate: DateTime(2026, 9, 10),
          revenue: 100,
          totalCogs: 40,
          totalProfit: 60,
          itemsCount: 2,
        ),
      ],
    );

    final export = ReportExportBuilders.sales(
      l10n: l10n,
      data: data,
      filters: const ['Company: Acme', 'Status: completed'],
    );

    expect(export.title, 'Sales Report');
    expect(export.filters, contains('Company: Acme'));
    expect(export.summary.first.value, '100.00');
    expect(export.rows.single[0], 'INV-1');
    expect(export.rows.single[4], '100.00');
    expect(export.rows.single[6], '60.00');
  });

  test('PDF and Excel builders encode bytes from export data', () async {
    final data = ReportExportData(
      title: 'Sales Report',
      fileStem: 'sales_report',
      filters: const ['Date: All'],
      summary: const [ReportExportMetric(label: 'Total Sales', value: '10.00')],
      columns: const ['Invoice', 'Total'],
      rows: const [
        ['INV-1', '10.00'],
      ],
    );

    final pdf = await PdfExportService.build(data);
    final xlsx = ExcelExportService.build(data);

    expect(pdf, isNotEmpty);
    expect(xlsx, isNotEmpty);
    // PDF magic header
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
  });

  test('Traditional Chinese export labels use 總利潤', () {
    final zh = lookupAppLocalizations(const Locale('zh', 'TW'));
    expect(zh.totalProfit, '總利潤');
    expect(zh.salesReport, '銷售報表');
  });
}
