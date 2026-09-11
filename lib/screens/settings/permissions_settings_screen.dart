import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/permission.dart';
import '../../state/auth_controller.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_surfaces.dart';

class PermissionsSettingsScreen extends StatelessWidget {
  const PermissionsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final permissions = AppPermissions(auth.user?.role ?? 'user');

    return AppScaffold(
      title: 'Roles & permissions',
      route: AppRoutes.settings,
      body: ListView(
        children: [
          AppSectionHeader(
            title: 'Roles & permissions',
            subtitle:
                'UI visibility follows your role. Database RLS still enforces security.',
            action: IconButton(
              tooltip: 'Back',
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.settings),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your role', style: AppTextStyles.caption),
                const SizedBox(height: 4),
                AppBadge(
                  label: auth.user?.role ?? 'user',
                  type: permissions.isAdmin
                      ? AppBadgeType.info
                      : AppBadgeType.neutral,
                ),
                const SizedBox(height: AppSizes.lg),
                Text('Granted capabilities', style: AppTextStyles.label),
                const SizedBox(height: AppSizes.sm),
                for (final label in permissions.grantedLabels)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(label)),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Admin-only actions (delete master data, stock adjustments, '
                  'user management, business settings) remain enforced in PostgreSQL.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
