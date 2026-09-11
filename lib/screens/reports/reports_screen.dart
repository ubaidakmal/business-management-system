import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../state/locale_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_surfaces.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final desktop = AppResponsive.isDesktop(context);
    final tablet = AppResponsive.isTablet(context);
    final crossAxisCount = desktop ? 3 : (tablet ? 2 : 1);

    final items = <_ReportLink>[
      _ReportLink(
        title: l10n.salesReports,
        subtitle: l10n.salesReportsSubtitle,
        icon: Icons.point_of_sale_outlined,
        route: AppRoutes.reportsSales,
        color: AppColors.info,
      ),
      _ReportLink(
        title: l10n.purchaseReports,
        subtitle: l10n.purchaseReportsSubtitle,
        icon: Icons.shopping_cart_outlined,
        route: AppRoutes.reportsPurchases,
        color: AppColors.warning,
      ),
      _ReportLink(
        title: l10n.profitReports,
        subtitle: l10n.profitReportsSubtitle,
        icon: Icons.trending_up,
        route: AppRoutes.reportsProfit,
        color: AppColors.success,
      ),
      _ReportLink(
        title: l10n.stockReports,
        subtitle: l10n.stockReportsSubtitle,
        icon: Icons.warehouse_outlined,
        route: AppRoutes.reportsStock,
        color: AppColors.info,
      ),
      _ReportLink(
        title: l10n.productReports,
        subtitle: l10n.productReportsSubtitle,
        icon: Icons.inventory_2_outlined,
        route: AppRoutes.reportsProducts,
        color: AppColors.warning,
      ),
      _ReportLink(
        title: l10n.companyReports,
        subtitle: l10n.companyReportsSubtitle,
        icon: Icons.apartment_outlined,
        route: AppRoutes.reportsCompanies,
        color: AppColors.success,
      ),
    ];

    return AppScaffold(
      title: l10n.reportsTitle,
      route: AppRoutes.reports,
      body: ListView(
        children: [
          AppSectionHeader(
            title: l10n.reportsTitle,
            subtitle: l10n.reportsSubtitle,
          ),
          const SizedBox(height: AppSizes.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = AppSizes.md;
              final width =
                  (constraints.maxWidth - gap * (crossAxisCount - 1)) /
                  crossAxisCount;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: width.clamp(200, constraints.maxWidth),
                      child: AppCard(
                        onTap: () => Navigator.pushNamed(context, item.route),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radius,
                                ),
                              ),
                              child: Icon(item.icon, color: item.color),
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: AppTextStyles.label),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.subtitle,
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportLink {
  const _ReportLink({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;
}
