import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../core/utils/formatters.dart';
import 'excel_export_service.dart';
import 'pdf_export_service.dart';
import 'report_export_data.dart';

/// Saves / prints already-built [ReportExportData] (no business recalculation).
abstract final class ReportExportService {
  static Future<void> exportPdf(ReportExportData data) async {
    final bytes = await PdfExportService.build(data);
    await Printing.sharePdf(
      bytes: bytes,
      filename: _fileName(data.fileStem, 'pdf'),
    );
  }

  static Future<void> exportExcel(ReportExportData data) async {
    final bytes = ExcelExportService.build(data);
    await FileSaver.instance.saveFile(
      name: _fileStemStamp(data.fileStem),
      bytes: bytes,
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  static Future<void> printReport(ReportExportData data) async {
    final bytes = await PdfExportService.build(data);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: data.title,
      format: PdfPageFormat.a4.landscape,
    );
  }

  static String _fileStemStamp(String stem) {
    final stamp = Formatters.date(DateTime.now()).replaceAll('-', '');
    return '${stem}_$stamp';
  }

  static String _fileName(String stem, String ext) {
    return '${_fileStemStamp(stem)}.$ext';
  }
}
