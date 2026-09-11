import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/utils/app_error.dart';
import '../../core/utils/responsive.dart';
import '../../export/report_export_data.dart';
import '../../export/report_export_service.dart';
import '../app_buttons.dart';
import '../app_feedback.dart';

enum ReportExportAction { pdf, excel, print }

class ReportExportActions extends StatefulWidget {
  const ReportExportActions({
    super.key,
    required this.buildData,
    this.enabled = true,
  });

  /// Builds export payload from the screen's current filtered state.
  final ReportExportData? Function() buildData;
  final bool enabled;

  @override
  State<ReportExportActions> createState() => _ReportExportActionsState();
}

class _ReportExportActionsState extends State<ReportExportActions> {
  ReportExportAction? _busy;

  Future<void> _run(ReportExportAction action) async {
    final data = widget.buildData();
    if (data == null) {
      AppSnackbar.show(
        context,
        'Load the report before exporting.',
        isError: true,
      );
      return;
    }

    setState(() => _busy = action);
    try {
      switch (action) {
        case ReportExportAction.pdf:
          await ReportExportService.exportPdf(data);
          if (mounted) AppSnackbar.show(context, 'PDF ready.');
        case ReportExportAction.excel:
          await ReportExportService.exportExcel(data);
          if (mounted) AppSnackbar.show(context, 'Excel file saved.');
        case ReportExportAction.print:
          await ReportExportService.printReport(data);
      }
    } catch (error) {
      if (mounted) {
        AppSnackbar.show(context, AppError.messageOf(error), isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);
    final enabled = widget.enabled && _busy == null;

    final buttons = [
      AppOutlinedButton(
        label: 'Export PDF',
        expanded: !desktop,
        onPressed: enabled ? () => _run(ReportExportAction.pdf) : null,
      ),
      AppOutlinedButton(
        label: 'Export Excel',
        expanded: !desktop,
        onPressed: enabled ? () => _run(ReportExportAction.excel) : null,
      ),
      AppOutlinedButton(
        label: desktop ? 'Print' : 'Print / Share',
        expanded: !desktop,
        onPressed: enabled ? () => _run(ReportExportAction.print) : null,
      ),
    ];

    if (_busy != null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    return Wrap(
      spacing: AppSizes.md,
      runSpacing: AppSizes.md,
      children: buttons,
    );
  }
}
