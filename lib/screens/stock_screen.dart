import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_sizes.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatters.dart';
import '../core/utils/responsive.dart';
import '../models/company.dart';
import '../models/stock_movement.dart';
import '../services/company_service.dart';
import '../services/stock_service.dart';
import '../state/app_status.dart';
import '../state/auth_controller.dart';
import '../state/stock_controller.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_fields.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_states.dart';
import '../widgets/app_surfaces.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _controller = StockController();
  final _companies = CompanyService();
  final _stockService = StockService();
  final _search = TextEditingController();
  Timer? _debounce;
  List<Company> _companyOptions = const [];
  List<String> _categories = const [];

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
      _categories = await _stockService.listCategories();
    } catch (_) {
      _companyOptions = const [];
      _categories = const [];
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

  Future<void> _openDetail(String productId) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.stockDetail,
      arguments: productId,
    );
    await _controller.load();
  }

  Future<void> _openAdjustment() async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.stockAdjustment,
    );
    if (changed == true) await _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);
    final isAdmin = AuthScope.of(context).user?.isAdmin == true;

    return AppScaffold(
      title: 'Stock',
      route: AppRoutes.stock,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: 'Inventory',
            subtitle:
                'Current stock = opening stock + movements. Costing comes later.',
            action: isAdmin
                ? AppButton(
                    label: 'Adjust stock',
                    expanded: false,
                    icon: Icons.tune,
                    onPressed: _openAdjustment,
                  )
                : null,
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
                  hint: 'Search product, SKU, company',
                  onChanged: _onSearch,
                ),
              ),
              SizedBox(
                width: desktop ? 200 : double.infinity,
                child: AppDropdown<String?>(
                  label: 'Company',
                  value: _controller.companyId,
                  hint: 'All companies',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    for (final company in _companyOptions)
                      DropdownMenuItem(
                        value: company.id,
                        child: Text(
                          company.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _controller.setCompanyFilter,
                ),
              ),
              SizedBox(
                width: desktop ? 180 : double.infinity,
                child: AppDropdown<String?>(
                  label: 'Category',
                  value: _controller.category,
                  hint: 'All',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    for (final category in _categories)
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: _controller.setCategoryFilter,
                ),
              ),
              SizedBox(
                width: desktop ? 150 : double.infinity,
                child: AppDropdown<bool?>(
                  label: 'Status',
                  value: _controller.isActive,
                  hint: 'All',
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: true, child: Text('Active')),
                    DropdownMenuItem(value: false, child: Text('Inactive')),
                  ],
                  onChanged: _controller.setActiveFilter,
                ),
              ),
              FilterChip(
                label: const Text('Low stock'),
                selected: _controller.lowStockOnly,
                onSelected: (value) => _controller.setLowStockOnly(value),
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
        message: 'Add products first, then complete purchases or adjust stock.',
      );
    }

    if (desktop) {
      return AppCard(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text('Product', style: AppTextStyles.label),
                  ),
                  Expanded(child: Text('SKU', style: AppTextStyles.label)),
                  Expanded(
                    flex: 2,
                    child: Text('Company', style: AppTextStyles.label),
                  ),
                  Expanded(child: Text('Stock', style: AppTextStyles.label)),
                  Expanded(child: Text('Reorder', style: AppTextStyles.label)),
                  Expanded(child: Text('Status', style: AppTextStyles.label)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: _controller.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return _desktopRow(_controller.items[index]);
                },
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _controller.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSizes.md),
      itemBuilder: (context, index) {
        final item = _controller.items[index];
        return AppCard(
          onTap: () => _openDetail(item.productId),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.productName,
                      style: AppTextStyles.headingSmall,
                    ),
                  ),
                  if (item.isLowStock)
                    const AppBadge(label: 'Low', type: AppBadgeType.warning),
                ],
              ),
              const SizedBox(height: 6),
              Text(item.companyName ?? '—', style: AppTextStyles.bodySmall),
              if (item.sku?.isNotEmpty == true)
                Text('SKU ${item.sku}', style: AppTextStyles.bodySmall),
              const SizedBox(height: 8),
              Text(
                'Stock ${Formatters.quantity(item.currentStock)}'
                '${item.unit == null ? '' : ' ${item.unit}'}'
                ' · Reorder ${Formatters.quantity(item.reorderLevel)}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _desktopRow(StockBalance item) {
    return InkWell(
      onTap: () => _openDetail(item.productId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                item.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                item.sku?.isNotEmpty == true ? item.sku! : '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.companyName ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(child: Text(Formatters.quantity(item.currentStock))),
            Expanded(child: Text(Formatters.quantity(item.reorderLevel))),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppBadge(
                  label: item.isLowStock ? 'Low' : 'OK',
                  type: item.isLowStock
                      ? AppBadgeType.warning
                      : AppBadgeType.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
