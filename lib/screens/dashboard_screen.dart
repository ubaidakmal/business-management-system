import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../state/auth_controller.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_surfaces.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final name = auth.user?.name?.trim();
    final greeting = (name == null || name.isEmpty)
        ? AppStrings.welcome
        : '${AppStrings.welcome}, $name';

    return AppScaffold(
      title: 'Dashboard',
      route: AppRoutes.dashboard,
      body: ListView(
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
          const SizedBox(height: 20),
          Text(
            'Manage companies, products, purchases, sales, and stock. '
            'Reports come in a later phase.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AppButton(
                label: 'Companies',
                expanded: false,
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.companies,
                ),
              ),
              AppOutlinedButton(
                label: 'Products',
                expanded: false,
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.products),
              ),
              AppOutlinedButton(
                label: 'Purchases',
                expanded: false,
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.purchases,
                ),
              ),
              AppOutlinedButton(
                label: 'Sales',
                expanded: false,
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.sales),
              ),
              AppOutlinedButton(
                label: 'Stock',
                expanded: false,
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.stock),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
