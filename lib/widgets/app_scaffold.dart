import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_strings.dart';
import '../core/routes/app_router.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/responsive.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.route,
  });

  final String title;
  final Widget body;
  final String? route;

  @override
  Widget build(BuildContext context) {
    final desktop = AppResponsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(title: Text(title, style: AppTextStyles.headingSmall)),
      drawer: desktop
          ? null
          : Drawer(child: _NavList(selectedRoute: route, inDrawer: true)),
      body: Row(
        children: [
          if (desktop)
            ColoredBox(
              color: AppColors.primary,
              child: SizedBox(
                width: AppSizes.navRailWidth,
                child: _NavList(selectedRoute: route),
              ),
            ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.contentMaxWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppResponsive.pagePadding(context)),
                  child: body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavList extends StatelessWidget {
  const _NavList({this.selectedRoute, this.inDrawer = false});

  final String? selectedRoute;
  final bool inDrawer;

  @override
  Widget build(BuildContext context) {
    final onNavy = !inDrawer;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              AppStrings.appName,
              style: AppTextStyles.headingSmall.copyWith(
                color: onNavy ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final item in AppRoutes.modules)
                  _NavTile(
                    item: item,
                    selected: item.route == selectedRoute,
                    onNavy: onNavy,
                    closeDrawer: inDrawer,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onNavy,
    required this.closeDrawer,
  });

  final AppDestination item;
  final bool selected;
  final bool onNavy;
  final bool closeDrawer;

  @override
  Widget build(BuildContext context) {
    final color = onNavy
        ? (selected ? Colors.white : Colors.white70)
        : (selected ? AppColors.primary : AppColors.textPrimary);

    return ListTile(
      leading: Icon(item.icon, color: color, size: 20),
      title: Text(
        item.label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: color,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: selected,
      selectedTileColor: onNavy
          ? Colors.white.withValues(alpha: 0.12)
          : AppColors.infoSoft,
      onTap: () {
        if (closeDrawer) Navigator.pop(context);
        if (item.route != ModalRoute.of(context)?.settings.name) {
          Navigator.pushReplacementNamed(context, item.route);
        }
      },
    );
  }
}
