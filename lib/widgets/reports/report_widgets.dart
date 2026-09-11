import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/app_fields.dart';
import '../../widgets/app_surfaces.dart';

class ReportDateFilters extends StatelessWidget {
  const ReportDateFilters({
    super.key,
    required this.dateFrom,
    required this.dateTo,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onClear,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);
    return Wrap(
      spacing: AppSizes.md,
      runSpacing: AppSizes.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: desktop ? 150 : double.infinity,
          child: OutlinedButton(
            onPressed: onPickFrom,
            child: Text(
              dateFrom == null ? 'From date' : Formatters.date(dateFrom),
            ),
          ),
        ),
        SizedBox(
          width: desktop ? 150 : double.infinity,
          child: OutlinedButton(
            onPressed: onPickTo,
            child: Text(dateTo == null ? 'To date' : Formatters.date(dateTo)),
          ),
        ),
        if (dateFrom != null || dateTo != null)
          TextButton(onPressed: onClear, child: const Text('Clear dates')),
      ],
    );
  }
}

class ReportCompanyFilter extends StatelessWidget {
  const ReportCompanyFilter({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final List<DropdownMenuItem<String?>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);
    return SizedBox(
      width: desktop ? 220 : double.infinity,
      child: AppDropdown<String?>(
        label: 'Company',
        value: value,
        hint: 'All companies',
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

class ReportKpiRow extends StatelessWidget {
  const ReportKpiRow({super.key, required this.cards});

  final List<AppStatCard> cards;

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);
    final tablet = AppResponsive.isTablet(context);
    final crossAxisCount = desktop
        ? (cards.length >= 4 ? 4 : cards.length)
        : (tablet ? 2 : 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AppSizes.md;
        final width =
            (constraints.maxWidth - gap * (crossAxisCount - 1)) /
            crossAxisCount;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(
                width: width.clamp(140, constraints.maxWidth),
                child: card,
              ),
          ],
        );
      },
    );
  }
}

class ReportTableHeader extends StatelessWidget {
  const ReportTableHeader({super.key, required this.columns});

  final List<(String label, int flex)> columns;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          for (final col in columns)
            Expanded(
              flex: col.$2,
              child: Text(col.$1, style: AppTextStyles.label),
            ),
        ],
      ),
    );
  }
}

String stockStatusLabel({
  required double currentStock,
  required bool isLowStock,
}) {
  if (currentStock <= 0) return 'Out of stock';
  if (isLowStock) return 'Low stock';
  return 'In stock';
}

AppBadgeType stockStatusType({
  required double currentStock,
  required bool isLowStock,
}) {
  if (currentStock <= 0) return AppBadgeType.error;
  if (isLowStock) return AppBadgeType.warning;
  return AppBadgeType.success;
}

Future<DateTime?> pickReportDate(
  BuildContext context, {
  required DateTime? initial,
}) {
  return showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
}
