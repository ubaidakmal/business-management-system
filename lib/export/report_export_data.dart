import '../core/utils/formatters.dart';

/// Neutral export payload built from already-filtered report data.
/// No stock/COGS/profit recalculation — values are display strings only.
class ReportExportMetric {
  const ReportExportMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class ReportExportData {
  const ReportExportData({
    required this.title,
    required this.fileStem,
    required this.filters,
    required this.summary,
    required this.columns,
    required this.rows,
    this.businessName = 'Business Management',
  });

  final String businessName;
  final String title;
  final String fileStem;
  final List<String> filters;
  final List<ReportExportMetric> summary;
  final List<String> columns;
  final List<List<String>> rows;

  String get generatedAtLabel => Formatters.dateTime(DateTime.now());
}
