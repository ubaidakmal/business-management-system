import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/company.dart';
import '../../models/product.dart';
import '../../models/report.dart';
import '../../services/company_service.dart';
import '../../export/report_export_builders.dart';
import '../../services/product_service.dart';
import '../../state/app_status.dart';
import '../../state/report_controllers.dart';
import '../../widgets/app_fields.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_surfaces.dart';
import '../../widgets/reports/report_export_actions.dart';
import '../../widgets/reports/report_widgets.dart';

class ProfitReportScreen extends StatefulWidget {
  const ProfitReportScreen({super.key});

  @override
  State<ProfitReportScreen> createState() => _ProfitReportScreenState();
}

class _ProfitReportScreenState extends State<ProfitReportScreen> {
  final _controller = ProfitReportController();
  final _companies = CompanyService();
  final _products = ProductService();
  List<Company> _companyOptions = const [];
  List<Product> _productOptions = const [];

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
    await _loadProducts();
    await _controller.load();
  }

  Future<void> _loadProducts() async {
    try {
      _productOptions = await _products.list(
        companyId: _controller.companyId,
        isActive: true,
      );
    } catch (_) {
      _productOptions = const [];
    }
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

  Future<void> _onCompanyChanged(String? value) async {
    await _controller.setCompanyFilter(value);
    await _loadProducts();
    if (_controller.productId != null &&
        !_productOptions.any((p) => p.id == _controller.productId)) {
      await _controller.setProductFilter(null);
    }
    if (mounted) setState(() {});
  }

  String? _companyName() {
    final id = _controller.companyId;
    if (id == null) return null;
    for (final company in _companyOptions) {
      if (company.id == id) return company.name;
    }
    return null;
  }

  String? _productName() {
    final id = _controller.productId;
    if (id == null) return null;
    for (final product in _productOptions) {
      if (product.id == id) return product.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);
    final summary = _controller.data?.summary ?? ProfitReportSummary.empty;

    return AppScaffold(
      title: 'Profit Reports',
      route: AppRoutes.reports,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: 'Profit Reports',
            subtitle: 'Uses Phase 7 stored COGS and profit (completed sales).',
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
              return ReportExportBuilders.profit(
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
                  'Product: ${_productName() ?? 'All'}',
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
                onChanged: _onCompanyChanged,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  for (final c in _companyOptions)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
              SizedBox(
                width: desktop ? 240 : double.infinity,
                child: AppDropdown<String?>(
                  label: 'Product',
                  value: _controller.productId,
                  hint: 'All products',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    for (final p in _productOptions)
                      DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: _controller.setProductFilter,
                ),
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
                label: 'Revenue',
                value: Formatters.money(summary.revenue),
                icon: Icons.payments_outlined,
                color: AppColors.info,
              ),
              AppStatCard(
                label: 'COGS',
                value: Formatters.money(summary.totalCogs),
                icon: Icons.inventory_outlined,
                color: AppColors.warning,
              ),
              AppStatCard(
                label: 'Gross Profit',
                value: Formatters.money(summary.grossProfit),
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
              AppStatCard(
                label: 'Number of Sales',
                value: '${summary.salesCount}',
                icon: Icons.receipt_long_outlined,
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
        title: 'No profit data',
        message: 'Complete sales in this range to see profit.',
      );
    }

    final rows = _controller.data!.rows;
    if (desktop) {
      return AppCard(
        child: Column(
          children: [
            const ReportTableHeader(
              columns: [
                ('Invoice', 2),
                ('Company', 2),
                ('Date', 1),
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
            AppRoutes.saleDetail,
            arguments: row.id,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.invoiceNumber?.isNotEmpty == true
                    ? row.invoiceNumber!
                    : 'Sale',
                style: AppTextStyles.headingSmall,
              ),
              Text(
                '${row.companyName ?? '—'} · ${Formatters.date(row.saleDate)}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Rev ${Formatters.money(row.revenue)} · '
                'COGS ${Formatters.money(row.totalCogs)} · '
                'Profit ${Formatters.money(row.grossProfit)}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _desktopRow(ProfitReportRow row) {
    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.saleDetail, arguments: row.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                row.invoiceNumber?.isNotEmpty == true
                    ? row.invoiceNumber!
                    : '—',
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
            Expanded(child: Text(Formatters.date(row.saleDate))),
            Expanded(child: Text(Formatters.money(row.revenue))),
            Expanded(child: Text(Formatters.money(row.totalCogs))),
            Expanded(child: Text(Formatters.money(row.grossProfit))),
          ],
        ),
      ),
    );
  }
}
