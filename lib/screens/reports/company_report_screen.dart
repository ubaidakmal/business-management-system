import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../export/report_export_builders.dart';
import '../../models/report.dart';
import '../../state/app_status.dart';
import '../../state/report_controllers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_surfaces.dart';
import '../../widgets/reports/report_export_actions.dart';
import '../../widgets/reports/report_widgets.dart';

class CompanyReportScreen extends StatefulWidget {
  const CompanyReportScreen({super.key});

  @override
  State<CompanyReportScreen> createState() => _CompanyReportScreenState();
}

class _CompanyReportScreenState extends State<CompanyReportScreen> {
  final _controller = CompanyReportController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refresh);
    _controller.load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await pickReportDate(
      context,
      initial: isFrom ? _controller.dateFrom : _controller.dateTo,
    );
    if (picked == null) return;
    await _controller.setDateRange(
      from: isFrom ? picked : _controller.dateFrom,
      to: isFrom ? _controller.dateTo : picked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);
    final summary = _controller.data?.summary ?? CompanyReportSummary.empty;

    return AppScaffold(
      title: 'Company Reports',
      route: AppRoutes.reports,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: 'Company Reports',
            subtitle: 'Sales, purchases, and profit by company.',
            action: IconButton(
              tooltip: 'Back',
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.reports),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          ReportExportActions(
            enabled: _controller.data != null && !_controller.isLoading,
            buildData: () {
              final data = _controller.data;
              if (data == null) return null;
              return ReportExportBuilders.companies(
                data: data,
                filters: [
                  ReportExportBuilders.dateRangeFilter(
                    _controller.dateFrom,
                    _controller.dateTo,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSizes.lg),
          ReportDateFilters(
            dateFrom: _controller.dateFrom,
            dateTo: _controller.dateTo,
            onPickFrom: () => _pickDate(isFrom: true),
            onPickTo: () => _pickDate(isFrom: false),
            onClear: () => _controller.setDateRange(),
          ),
          const SizedBox(height: AppSizes.lg),
          ReportKpiRow(
            cards: [
              AppStatCard(
                label: 'Companies',
                value: '${summary.companyCount}',
                icon: Icons.apartment_outlined,
              ),
              AppStatCard(
                label: 'Sales Total',
                value: Formatters.money(summary.salesTotal),
                icon: Icons.point_of_sale_outlined,
                color: AppColors.info,
              ),
              AppStatCard(
                label: 'Purchases Total',
                value: Formatters.money(summary.purchasesTotal),
                icon: Icons.shopping_cart_outlined,
                color: AppColors.warning,
              ),
              AppStatCard(
                label: 'Profit Total',
                value: Formatters.money(summary.profitTotal),
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Expanded(child: _buildBody(desktop: desktop)),
        ],
      ),
    );
  }

  Widget _buildBody({required bool desktop}) {
    if (_controller.isLoading || _controller.status.isInitial) {
      return const AppLoading();
    }
    if (_controller.status.hasError) {
      return AppErrorState(
        message: _controller.errorMessage,
        onRetry: _controller.load,
      );
    }
    if (_controller.status.isEmpty) {
      return const AppEmptyState(
        title: 'No companies',
        message: 'Add companies to see this report.',
      );
    }

    final rows = _controller.data!.rows;
    if (desktop) {
      return AppCard(
        child: Column(
          children: [
            const ReportTableHeader(
              columns: [
                ('Company', 2),
                ('Sales', 1),
                ('Purchases', 1),
                ('Profit', 1),
                ('Products', 1),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => _desktopRow(rows[index]),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSizes.md),
      itemBuilder: (context, index) {
        final row = rows[index];
        return AppCard(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.companyDetail,
            arguments: row.companyId,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row.companyName, style: AppTextStyles.headingSmall),
              if (row.code != null && row.code!.isNotEmpty)
                Text(row.code!, style: AppTextStyles.bodySmall),
              const SizedBox(height: 8),
              Text(
                'Sales ${Formatters.money(row.salesTotal)} · '
                'Purchases ${Formatters.money(row.purchasesTotal)} · '
                'Profit ${Formatters.money(row.profitTotal)} · '
                'Products ${row.productCount}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _desktopRow(CompanyReportRow row) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.companyDetail,
        arguments: row.companyId,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                row.companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(child: Text(Formatters.money(row.salesTotal))),
            Expanded(child: Text(Formatters.money(row.purchasesTotal))),
            Expanded(child: Text(Formatters.money(row.profitTotal))),
            Expanded(child: Text('${row.productCount}')),
          ],
        ),
      ),
    );
  }
}
