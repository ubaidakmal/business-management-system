import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_strings.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatters.dart';
import '../core/utils/responsive.dart';
import '../models/company.dart';
import '../models/dashboard.dart';
import '../services/company_service.dart';
import '../state/app_status.dart';
import '../state/auth_controller.dart';
import '../state/dashboard_controller.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_fields.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_states.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/dashboard_trend_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _controller = DashboardController();
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

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _controller.dateFrom,
        end: _controller.dateTo,
      ),
    );
    if (range == null) return;
    await _controller.setCustomRange(from: range.start, to: range.end);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final name = auth.user?.name?.trim();
    final greeting = (name == null || name.isEmpty)
        ? AppStrings.welcome
        : '${AppStrings.welcome}, $name';
    final desktop = AppResponsive.isDesktop(context);
    final tablet = AppResponsive.isTablet(context);

    return AppScaffold(
      title: 'Dashboard',
      route: AppRoutes.dashboard,
      body: RefreshIndicator(
        onRefresh: _controller.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AppSectionHeader(
              title: greeting,
              subtitle: auth.user?.email,
              action: AppBadge(
                label: auth.user?.role ?? 'user',
                type: auth.user?.isAdmin == true
                    ? AppBadgeType.info
                    : AppBadgeType.neutral,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            _FiltersBar(
              controller: _controller,
              companies: _companyOptions,
              desktop: desktop,
              onCustomRange: _pickCustomRange,
            ),
            const SizedBox(height: AppSizes.lg),
            _buildBody(desktop: desktop, tablet: tablet),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({required bool desktop, required bool tablet}) {
    if (_controller.status.isLoading && _controller.data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: AppLoading(message: 'Loading dashboard…'),
      );
    }
    if (_controller.status.hasError && _controller.data == null) {
      return AppErrorState(
        message: _controller.errorMessage,
        onRetry: _controller.load,
      );
    }

    final data = _controller.data;
    if (data == null) {
      return const AppEmptyState(
        title: 'No dashboard data',
        message: 'Pull to refresh or adjust filters.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_controller.status.isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSizes.md),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        _KpiGrid(summary: data.summary, desktop: desktop, tablet: tablet),
        const SizedBox(height: AppSizes.xl),
        _QuickActions(desktop: desktop),
        const SizedBox(height: AppSizes.xl),
        if (desktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppSectionHeader(
                        title: 'Sales & profit trend',
                        subtitle: 'Completed sales in the selected range',
                      ),
                      const SizedBox(height: AppSizes.md),
                      DashboardTrendChart(points: data.trend),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.lg),
              Expanded(
                flex: 2,
                child: _InventoryCard(
                  inventory: data.inventory,
                  lowStock: data.lowStock,
                ),
              ),
            ],
          )
        else ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSectionHeader(
                  title: 'Sales & profit trend',
                  subtitle: 'Completed sales in the selected range',
                ),
                const SizedBox(height: AppSizes.md),
                if (data.trend.length > 14)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: data.trend.length * 28.0,
                      child: DashboardTrendChart(points: data.trend),
                    ),
                  )
                else
                  DashboardTrendChart(points: data.trend),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          _InventoryCard(inventory: data.inventory, lowStock: data.lowStock),
        ],
        const SizedBox(height: AppSizes.xl),
        if (desktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _RecentSalesCard(sales: data.recentSales)),
              const SizedBox(width: AppSizes.lg),
              Expanded(
                child: _RecentPurchasesCard(purchases: data.recentPurchases),
              ),
            ],
          )
        else ...[
          _RecentSalesCard(sales: data.recentSales),
          const SizedBox(height: AppSizes.lg),
          _RecentPurchasesCard(purchases: data.recentPurchases),
        ],
        const SizedBox(height: AppSizes.xxl),
      ],
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.controller,
    required this.companies,
    required this.desktop,
    required this.onCustomRange,
  });

  final DashboardController controller;
  final List<Company> companies;
  final bool desktop;
  final VoidCallback onCustomRange;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.md,
      runSpacing: AppSizes.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final preset in DashboardRangePreset.values)
          FilterChip(
            label: Text(_presetLabel(preset)),
            selected: controller.preset == preset,
            onSelected: (_) {
              if (preset == DashboardRangePreset.custom) {
                onCustomRange();
              } else {
                controller.setPreset(preset);
              }
            },
          ),
        Text(
          '${Formatters.date(controller.dateFrom)} → ${Formatters.date(controller.dateTo)}',
          style: AppTextStyles.caption,
        ),
        SizedBox(
          width: desktop ? 220 : double.infinity,
          child: AppDropdown<String?>(
            label: 'Company',
            value: controller.companyId,
            hint: 'All companies',
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              for (final company in companies)
                DropdownMenuItem(
                  value: company.id,
                  child: Text(company.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: controller.setCompanyFilter,
          ),
        ),
        AppIconButton(
          icon: Icons.refresh,
          tooltip: 'Refresh',
          onPressed: controller.load,
        ),
      ],
    );
  }

  String _presetLabel(DashboardRangePreset preset) {
    return switch (preset) {
      DashboardRangePreset.today => 'Today',
      DashboardRangePreset.week => 'This week',
      DashboardRangePreset.month => 'This month',
      DashboardRangePreset.custom => 'Custom',
    };
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.summary,
    required this.desktop,
    required this.tablet,
  });

  final DashboardSummary summary;
  final bool desktop;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final cards = [
      AppStatCard(
        label: 'Total Sales',
        value: Formatters.money(summary.salesTotal),
        icon: Icons.point_of_sale_outlined,
        color: AppColors.info,
      ),
      AppStatCard(
        label: 'Total Purchases',
        value: Formatters.money(summary.purchasesTotal),
        icon: Icons.shopping_cart_outlined,
        color: AppColors.warning,
      ),
      AppStatCard(
        label: 'Total Revenue',
        value: Formatters.money(summary.revenue),
        icon: Icons.payments_outlined,
        color: AppColors.info,
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
      AppStatCard(
        label: 'Number of Sales',
        value: '${summary.salesCount}',
        icon: Icons.receipt_long_outlined,
        color: AppColors.info,
      ),
      AppStatCard(
        label: 'Number of Purchases',
        value: '${summary.purchasesCount}',
        icon: Icons.receipt_outlined,
        color: AppColors.warning,
      ),
    ];

    final crossAxisCount = desktop ? 4 : (tablet ? 2 : 1);
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.desktop});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionHeader(
            title: 'Quick actions',
            subtitle: 'Common shortcuts',
          ),
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.md,
            runSpacing: AppSizes.md,
            children: [
              AppButton(
                label: 'Add Sale',
                expanded: !desktop,
                icon: Icons.add,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.saleForm),
              ),
              AppOutlinedButton(
                label: 'Add Purchase',
                expanded: !desktop,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.purchaseForm),
              ),
              AppOutlinedButton(
                label: 'Add Product',
                expanded: !desktop,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.productForm),
              ),
              AppOutlinedButton(
                label: 'View Stock',
                expanded: !desktop,
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.stock),
              ),
              AppOutlinedButton(
                label: 'Companies',
                expanded: !desktop,
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.companies,
                ),
              ),
              AppOutlinedButton(
                label: 'Reports',
                expanded: !desktop,
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.reports),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.inventory, required this.lowStock});

  final DashboardInventory inventory;
  final List<DashboardLowStockItem> lowStock;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionHeader(
            title: 'Inventory summary',
            subtitle: 'From product stock balances',
          ),
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.md,
            runSpacing: AppSizes.md,
            children: [
              _MiniStat(label: 'Products', value: '${inventory.totalProducts}'),
              _MiniStat(
                label: 'Low stock',
                value: '${inventory.lowStockCount}',
                color: AppColors.warning,
              ),
              _MiniStat(
                label: 'Out of stock',
                value: '${inventory.outOfStockCount}',
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Text('Low-stock products', style: AppTextStyles.label),
          const SizedBox(height: AppSizes.sm),
          if (lowStock.isEmpty)
            Text('No low-stock products.', style: AppTextStyles.bodySmall)
          else
            for (final item in lowStock)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  item.productName,
                  style: AppTextStyles.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    if (item.sku != null && item.sku!.isNotEmpty) item.sku!,
                    if (item.companyName != null) item.companyName!,
                    'Reorder ${Formatters.quantity(item.reorderLevel)}',
                  ].join(' · '),
                  style: AppTextStyles.caption,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  Formatters.quantity(item.currentStock),
                  style: AppTextStyles.label.copyWith(
                    color: item.currentStock <= 0
                        ? AppColors.error
                        : AppColors.warning,
                  ),
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.stockDetail,
                  arguments: item.productId,
                ),
              ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.headingSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _RecentSalesCard extends StatelessWidget {
  const _RecentSalesCard({required this.sales});

  final List<DashboardRecentSale> sales;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionHeader(
            title: 'Recent sales',
            subtitle: 'Completed only',
          ),
          const SizedBox(height: AppSizes.sm),
          if (sales.isEmpty)
            Text('No sales in this range.', style: AppTextStyles.bodySmall)
          else
            for (final sale in sales)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  sale.invoiceNumber?.isNotEmpty == true
                      ? sale.invoiceNumber!
                      : 'Sale',
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    sale.companyName ?? '—',
                    Formatters.date(sale.saleDate),
                  ].join(' · '),
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.money(sale.totalAmount),
                      style: AppTextStyles.label,
                    ),
                    Text(
                      'P ${Formatters.money(sale.totalProfit)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.saleDetail,
                  arguments: sale.id,
                ),
              ),
        ],
      ),
    );
  }
}

class _RecentPurchasesCard extends StatelessWidget {
  const _RecentPurchasesCard({required this.purchases});

  final List<DashboardRecentPurchase> purchases;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionHeader(
            title: 'Recent purchases',
            subtitle: 'Completed only',
          ),
          const SizedBox(height: AppSizes.sm),
          if (purchases.isEmpty)
            Text('No purchases in this range.', style: AppTextStyles.bodySmall)
          else
            for (final purchase in purchases)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  purchase.invoiceNumber?.isNotEmpty == true
                      ? purchase.invoiceNumber!
                      : 'Purchase',
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    purchase.companyName ?? '—',
                    Formatters.date(purchase.purchaseDate),
                  ].join(' · '),
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                trailing: Text(
                  Formatters.money(purchase.totalAmount),
                  style: AppTextStyles.label,
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.purchaseDetail,
                  arguments: purchase.id,
                ),
              ),
        ],
      ),
    );
  }
}
