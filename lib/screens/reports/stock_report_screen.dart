import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/company.dart';
import '../../models/stock_movement.dart';
import '../../export/report_export_builders.dart';
import '../../services/company_service.dart';
import '../../state/app_status.dart';
import '../../state/report_controllers.dart';
import '../../widgets/app_fields.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_surfaces.dart';
import '../../widgets/reports/report_export_actions.dart';
import '../../widgets/reports/report_widgets.dart';

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  final _controller = StockReportController();
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
    await _controller.bootstrap();
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

  String? _companyName() {
    final id = _controller.companyId;
    if (id == null) return null;
    for (final company in _companyOptions) {
      if (company.id == id) return company.name;
    }
    return null;
  }

  Future<void> _showMovements(StockBalance balance) async {
    List<StockMovement> movements;
    try {
      movements = await _controller.movementsFor(balance.productId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Movements · ${balance.productName}',
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: AppSizes.md),
                if (movements.isEmpty)
                  const Text('No movements yet.')
                else
                  SizedBox(
                    height: 320,
                    child: ListView.separated(
                      itemCount: movements.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final m = movements[index];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(m.typeLabel),
                          subtitle: Text(Formatters.dateTime(m.createdAt)),
                          trailing: Text(
                            Formatters.quantity(m.quantity),
                            style: AppTextStyles.label,
                          ),
                        );
                      },
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);
    final items = _controller.items;
    final lowCount = items
        .where((i) => i.isLowStock && i.currentStock > 0)
        .length;
    final outCount = items.where((i) => i.currentStock <= 0).length;

    return AppScaffold(
      title: 'Stock Reports',
      route: AppRoutes.reports,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: 'Stock Reports',
            subtitle: 'From product_stock_balances (opening + movements).',
            action: IconButton(
              tooltip: 'Back',
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.reports),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          ReportExportActions(
            enabled:
                !_controller.isLoading &&
                (_controller.status.isSuccess || _controller.status.isEmpty),
            buildData: () {
              if (_controller.status.hasError || _controller.status.isInitial) {
                return null;
              }
              return ReportExportBuilders.stock(
                items: _controller.items,
                filters: [
                  ReportExportBuilders.companyFilter(
                    _controller.companyId,
                    _companyName(),
                  ),
                  'Category: ${_controller.category ?? 'All'}',
                  if (_controller.lowStockOnly) 'Filter: Low stock',
                  if (_controller.outOfStockOnly) 'Filter: Out of stock',
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
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: desktop ? 240 : double.infinity,
                child: AppSearchField(
                  controller: _search,
                  hint: 'Search product, SKU, company',
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
                width: desktop ? 180 : double.infinity,
                child: AppDropdown<String?>(
                  label: 'Category',
                  value: _controller.category,
                  hint: 'All',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    for (final cat in _controller.categories)
                      DropdownMenuItem(value: cat, child: Text(cat)),
                  ],
                  onChanged: _controller.setCategory,
                ),
              ),
              FilterChip(
                label: const Text('Low stock'),
                selected: _controller.lowStockOnly,
                onSelected: _controller.setLowStockOnly,
              ),
              FilterChip(
                label: const Text('Out of stock'),
                selected: _controller.outOfStockOnly,
                onSelected: _controller.setOutOfStockOnly,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          ReportKpiRow(
            cards: [
              AppStatCard(
                label: 'Products shown',
                value: '${items.length}',
                icon: Icons.inventory_2_outlined,
              ),
              AppStatCard(
                label: 'Low stock',
                value: '$lowCount',
                icon: Icons.warning_amber_outlined,
                color: AppColors.warning,
              ),
              AppStatCard(
                label: 'Out of stock',
                value: '$outCount',
                icon: Icons.remove_shopping_cart_outlined,
                color: AppColors.error,
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
        title: 'No stock rows',
        message: 'Adjust filters or add products.',
      );
    }

    final rows = _controller.items;
    if (desktop) {
      return AppCard(
        child: Column(
          children: [
            const ReportTableHeader(
              columns: [
                ('Product', 2),
                ('Company', 2),
                ('Stock', 1),
                ('Reorder', 1),
                ('Status', 1),
                ('', 1),
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
            AppRoutes.stockDetail,
            arguments: row.productId,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      row.productName,
                      style: AppTextStyles.headingSmall,
                    ),
                  ),
                  AppBadge(
                    label: stockStatusLabel(
                      currentStock: row.currentStock,
                      isLowStock: row.isLowStock,
                    ),
                    type: stockStatusType(
                      currentStock: row.currentStock,
                      isLowStock: row.isLowStock,
                    ),
                  ),
                ],
              ),
              Text(row.companyName ?? '—', style: AppTextStyles.bodySmall),
              Text(
                'Stock ${Formatters.quantity(row.currentStock)} · '
                'Reorder ${Formatters.quantity(row.reorderLevel)}',
              ),
              TextButton(
                onPressed: () => _showMovements(row),
                child: const Text('Movement history'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _desktopRow(StockBalance row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.stockDetail,
                arguments: row.productId,
              ),
              child: Text(
                row.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
          Expanded(child: Text(Formatters.quantity(row.currentStock))),
          Expanded(child: Text(Formatters.quantity(row.reorderLevel))),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppBadge(
                label: stockStatusLabel(
                  currentStock: row.currentStock,
                  isLowStock: row.isLowStock,
                ),
                type: stockStatusType(
                  currentStock: row.currentStock,
                  isLowStock: row.isLowStock,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: () => _showMovements(row),
              child: const Text('History'),
            ),
          ),
        ],
      ),
    );
  }
}
