import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/company.dart';
import '../../models/report.dart';
import '../../export/report_export_builders.dart';
import '../../services/company_service.dart';
import '../../state/app_status.dart';
import '../../state/report_controllers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_surfaces.dart';
import '../../widgets/reports/report_export_actions.dart';
import '../../widgets/reports/report_widgets.dart';

class ProductReportScreen extends StatefulWidget {
  const ProductReportScreen({super.key});

  @override
  State<ProductReportScreen> createState() => _ProductReportScreenState();
}

class _ProductReportScreenState extends State<ProductReportScreen> {
  final _controller = ProductReportController();
  final _companies = CompanyService();
  List<Company> _companyOptions = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refresh);
    _bootstrap();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    try {
      _companyOptions = await _companies.list(isActive: true);
    } catch (_) {
      _companyOptions = const [];
    }
    await _controller.load();
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

  String? _companyName() {
    final id = _controller.companyId;
    if (id == null) return null;
    for (final company in _companyOptions) {
      if (company.id == id) return company.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);
    final summary = _controller.data?.summary ?? ProductReportSummary.empty;

    return AppScaffold(
      title: 'Product Reports',
      route: AppRoutes.reports,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: 'Product Reports',
            subtitle: 'Performance from completed sale lines.',
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
              return ReportExportBuilders.products(
                data: data,
                filters: [
                  ReportExportBuilders.dateRangeFilter(
                    _controller.dateFrom,
                    _controller.dateTo,
                  ),
                  ReportExportBuilders.companyFilter(
                    _controller.companyId,
                    _companyName(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSizes.lg),
          Wrap(
            spacing: AppSizes.md,
            runSpacing: AppSizes.md,
            children: [
              ReportCompanyFilter(
                value: _controller.companyId,
                onChanged: _controller.setCompanyFilter,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  for (final c in _companyOptions)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
              ReportDateFilters(
                dateFrom: _controller.dateFrom,
                dateTo: _controller.dateTo,
                onPickFrom: () => _pickDate(isFrom: true),
                onPickTo: () => _pickDate(isFrom: false),
                onClear: () => _controller.setDateRange(),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          ReportKpiRow(
            cards: [
              AppStatCard(
                label: 'Products',
                value: '${summary.productCount}',
                icon: Icons.inventory_2_outlined,
              ),
              AppStatCard(
                label: 'Qty Sold',
                value: Formatters.quantity(summary.quantitySold),
                icon: Icons.shopping_bag_outlined,
                color: AppColors.info,
              ),
              AppStatCard(
                label: 'Revenue',
                value: Formatters.money(summary.revenue),
                icon: Icons.payments_outlined,
              ),
              AppStatCard(
                label: 'Profit',
                value: Formatters.money(summary.totalProfit),
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
        title: 'No product sales',
        message: 'Complete sales to see product performance.',
      );
    }

    final rows = _controller.data!.rows;
    if (desktop) {
      return AppCard(
        child: Column(
          children: [
            const ReportTableHeader(
              columns: [
                ('Product', 2),
                ('Company', 2),
                ('Qty Sold', 1),
                ('Revenue', 1),
                ('COGS', 1),
                ('Profit', 1),
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
            AppRoutes.productDetail,
            arguments: row.productId,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row.productName, style: AppTextStyles.headingSmall),
              Text(row.companyName ?? '—', style: AppTextStyles.bodySmall),
              const SizedBox(height: 8),
              Text(
                'Qty ${Formatters.quantity(row.quantitySold)} · '
                'Rev ${Formatters.money(row.revenue)} · '
                'COGS ${Formatters.money(row.totalCogs)} · '
                'Profit ${Formatters.money(row.totalProfit)}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _desktopRow(ProductReportRow row) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.productDetail,
        arguments: row.productId,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                row.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                row.companyName ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(child: Text(Formatters.quantity(row.quantitySold))),
            Expanded(child: Text(Formatters.money(row.revenue))),
            Expanded(child: Text(Formatters.money(row.totalCogs))),
            Expanded(child: Text(Formatters.money(row.totalProfit))),
          ],
        ),
      ),
    );
  }
}
