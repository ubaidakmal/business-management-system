import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../state/app_status.dart';
import '../../state/settings_controller.dart';
import '../../widgets/admin_gate.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_surfaces.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final _controller = AdminOverviewController();

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

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);
    final o = _controller.overview;

    return AdminGate(
      child: AppScaffold(
        title: 'Administration',
        route: AppRoutes.settings,
        body: RefreshIndicator(
          onRefresh: _controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              AppSectionHeader(
                title: 'Administration',
                subtitle: 'System overview and user management',
                action: IconButton(
                  tooltip: 'Back to settings',
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.settings,
                  ),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              if (_controller.isLoading)
                const AppLoading()
              else if (_controller.status.hasError)
                AppErrorState(
                  message: _controller.errorMessage,
                  onRetry: _controller.load,
                )
              else ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final count = desktop ? 4 : 2;
                    final gap = AppSizes.md;
                    final width =
                        (constraints.maxWidth - gap * (count - 1)) / count;
                    final cards = [
                      AppStatCard(
                        label: 'Users',
                        value: '${o.usersTotal}',
                        icon: Icons.people_outline,
                      ),
                      AppStatCard(
                        label: 'Active users',
                        value: '${o.usersActive}',
                        icon: Icons.verified_user_outlined,
                        color: AppColors.success,
                      ),
                      AppStatCard(
                        label: 'Admins',
                        value: '${o.usersAdmins}',
                        icon: Icons.admin_panel_settings_outlined,
                        color: AppColors.info,
                      ),
                      AppStatCard(
                        label: 'Companies',
                        value: '${o.companiesActive}',
                        icon: Icons.apartment_outlined,
                      ),
                      AppStatCard(
                        label: 'Products',
                        value: '${o.productsActive}',
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.warning,
                      ),
                    ];
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
                ),
                const SizedBox(height: AppSizes.xl),
                AppCard(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.adminUsers),
                  child: Row(
                    children: [
                      const Icon(Icons.group_outlined),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User management', style: AppTextStyles.label),
                            Text(
                              'View users, roles, and active status',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                AppCard(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.settingsBusiness),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_outlined),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business settings',
                              style: AppTextStyles.label,
                            ),
                            Text(
                              'Update business profile used in exports',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  'Totals: ${o.companiesTotal} companies · ${o.productsTotal} products',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
