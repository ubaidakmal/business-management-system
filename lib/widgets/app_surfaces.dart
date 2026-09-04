import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/theme/app_text_styles.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.lg),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        side: const BorderSide(color: AppColors.border),
      ),
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSizes.radius),
              child: content,
            ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headingSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: AppTextStyles.bodySmall),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.info,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radius),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.headingSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum AppBadgeType { success, warning, error, info, neutral }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.type = AppBadgeType.neutral,
  });

  final String label;
  final AppBadgeType type;

  @override
  Widget build(BuildContext context) {
    final colors = switch (type) {
      AppBadgeType.success => (AppColors.successSoft, AppColors.success),
      AppBadgeType.warning => (AppColors.warningSoft, AppColors.warning),
      AppBadgeType.error => (AppColors.errorSoft, AppColors.error),
      AppBadgeType.info => (AppColors.infoSoft, AppColors.info),
      AppBadgeType.neutral => (AppColors.background, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: colors.$2),
      ),
    );
  }
}
