import 'dart:async';

import 'package:flutter/material.dart';

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

class PurchasesReportScreen extends StatefulWidget {
  const PurchasesReportScreen({super.key});

  @override
  State<PurchasesReportScreen> createState() => _PurchasesReportScreenState();
}

class _PurchasesReportScreenState extends State<PurchasesReportScreen> {
  final _controller = PurchasesReportController();
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
    final summary = _controller.data?.summary ?? PurchasesReportSummary.empty;

    return AppScaffold(
      title: 'Purchase Reports',
      route: AppRoutes.reports,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: 'Purchase Reports',
            subtitle: 'Completed purchases only.',
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
              return ReportExportBuilders.purchases(
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
                label: 'Purchase Total',
                value: Formatters.money(summary.purchasesTotal),
                icon: Icons.shopping_cart_outlined,
                color: AppColors.warning,
              ),
              AppStatCard(
                label: 'Number of Purchases',
                value: '${summary.purchasesCount}',
                icon: Icons.receipt_outlined,
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
        title: 'No purchases found',
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
                ('Total', 1),
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
            AppRoutes.purchaseDetail,
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
              Text(Formatters.date(row.purchaseDate)),
              const SizedBox(height: 8),
              Text(
                'Items ${row.itemsCount} · Total ${Formatters.money(row.totalAmount)}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _desktopRow(PurchasesReportRow row) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.purchaseDetail,
        arguments: row.id,
      ),
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
            Expanded(child: Text(Formatters.date(row.purchaseDate))),
            Expanded(child: Text('${row.itemsCount}')),
            Expanded(child: Text(Formatters.money(row.totalAmount))),
          ],
        ),
      ),
    );
  }
}
