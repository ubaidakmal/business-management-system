import 'package:flutter/material.dart';

import '../../screens/login_screen.dart';
import '../../screens/placeholder_screen.dart';
import '../../screens/splash_screen.dart';
import '../constants/app_strings.dart';

class AppDestination {
  const AppDestination({
    required this.route,
    required this.label,
    required this.icon,
  });

  final String route;
  final String label;
  final IconData icon;
}

abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const companies = '/companies';
  static const products = '/products';
  static const purchases = '/purchases';
  static const sales = '/sales';
  static const stock = '/stock';
  static const reports = '/reports';
  static const settings = '/settings';

  static const modules = <AppDestination>[
    AppDestination(
      route: dashboard,
      label: 'Dashboard',
      icon: Icons.space_dashboard_outlined,
    ),
    AppDestination(
      route: companies,
      label: 'Companies',
      icon: Icons.apartment_outlined,
    ),
    AppDestination(
      route: products,
      label: 'Products',
      icon: Icons.inventory_2_outlined,
    ),
    AppDestination(
      route: purchases,
      label: 'Purchases',
      icon: Icons.shopping_cart_outlined,
    ),
    AppDestination(
      route: sales,
      label: 'Sales',
      icon: Icons.point_of_sale_outlined,
    ),
    AppDestination(
      route: stock,
      label: 'Stock',
      icon: Icons.warehouse_outlined,
    ),
    AppDestination(
      route: reports,
      label: 'Reports',
      icon: Icons.bar_chart_outlined,
    ),
    AppDestination(
      route: settings,
      label: 'Settings',
      icon: Icons.settings_outlined,
    ),
  ];
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? AppRoutes.splash;
    final builder = switch (name) {
      AppRoutes.splash => (_) => const SplashScreen(),
      AppRoutes.login => (_) => const LoginScreen(),
      _ => (_) => PlaceholderScreen(title: _titleFor(name), route: name),
    };

    return MaterialPageRoute<void>(settings: settings, builder: builder);
  }

  static String _titleFor(String route) {
    for (final module in AppRoutes.modules) {
      if (module.route == route) return module.label;
    }
    return AppStrings.appName;
  }
}
