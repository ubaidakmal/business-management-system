import 'dart:async';

import 'package:flutter/material.dart';

import '../../state/locale_controller.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/company.dart';
import '../../models/report.dart';
import '../../services/company_service.dart';
import '../../state/app_status.dart';
import '../../state/report_controllers.dart';
import '../../widgets/app_fields.dart';
import '../../export/report_export_builders.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_surfaces.dart';
import '../../widgets/reports/report_export_actions.dart';
import '../../widgets/reports/report_widgets.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final _controller = SalesReportController();
  final _search = TextEditingController();
  final _companies = CompanyService();
  Timer? _debounce;
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
    _debounce?.cancel();
    _controller.removeListener(_refresh);
    _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _controller.search(value);
    });
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
    final summary = _controller.data?.summary ?? SalesReportSummary.empty;

    return AppScaffold(
      title: 'Sales Reports',
      route: AppRoutes.reports,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: 'Sales Reports',
            subtitle: 'Cancelled sales are excluded. Totals use stored values.',
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
              return ReportExportBuilders.sales(
                l10n: context.l10n,
                data: data,
                filters: [
                  ReportExportBuilders.dateRangeFilter(
                    context.l10n,
                    _controller.dateFrom,
                    _controller.dateTo,
                  ),
                  ReportExportBuilders.companyFilter(
                    context.l10n,
                    _controller.companyId,
                    _companyName(),
                  ),
                  'Status: ${_controller.statusFilter}',
                  if (_controller.searchQuery.trim().isNotEmpty)
                    'Search: ${_controller.searchQuery.trim()}',
                ],
              );
            },
          ),
          const SizedBox(height: AppSizes.lg),
          Wrap(
            spacing: AppSizes.md,
            runSpacing: AppSizes.md,
            children: [
              SizedBox(
                width: desktop ? 260 : double.infinity,
                child: AppSearchField(
                  controller: _search,
                  hint: 'Search invoice, reference, company',
                  onChanged: _onSearch,
                ),
              ),
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
              SizedBox(
                width: desktop ? 160 : double.infinity,
                child: AppDropdown<String>(
                  label: 'Status',
                  value: _controller.statusFilter,
                  items: const [
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  ],
                  onChanged: (v) {
                    if (v != null) _controller.setStatusFilter(v);
                  },
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
                label: 'Total Sales',
                value: Formatters.money(summary.salesTotal),
                icon: Icons.payments_outlined,
                color: AppColors.info,
              ),
              AppStatCard(
                label: 'Number of Sales',
                value: '${summary.salesCount}',
                icon: Icons.receipt_long_outlined,
              ),
              AppStatCard(
                label: 'Total COGS',
                value: Formatters.money(summary.totalCogs),
                icon: Icons.inventory_outlined,
                color: AppColors.warning,
              ),
              AppStatCard(
                label: 'Total Profit',
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
        title: 'No sales found',
        message: 'Try a different date range or filter.',
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
                ('Items', 1),
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
                    : 'No invoice',
                style: AppTextStyles.headingSmall,
              ),
              Text(row.companyName ?? '—', style: AppTextStyles.bodySmall),
              Text(Formatters.date(row.saleDate)),
              const SizedBox(height: 8),
              Text(
                'Items ${row.itemsCount} · Rev ${Formatters.money(row.revenue)} · '
                'COGS ${Formatters.money(row.totalCogs)} · '
                'Profit ${Formatters.money(row.totalProfit)}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _desktopRow(SalesReportRow row) {
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
            Expanded(child: Text('${row.itemsCount}')),
            Expanded(child: Text(Formatters.money(row.revenue))),
            Expanded(child: Text(Formatters.money(row.totalCogs))),
            Expanded(child: Text(Formatters.money(row.totalProfit))),
          ],
        ),
      ),
    );
  }
}
