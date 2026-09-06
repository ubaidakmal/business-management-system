import 'package:flutter/material.dart';

import '../../screens/companies_screen.dart';
import '../../screens/company_detail_screen.dart';
import '../../screens/company_form_screen.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/forgot_password_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/placeholder_screen.dart';
import '../../screens/product_detail_screen.dart';
import '../../screens/product_form_screen.dart';
import '../../screens/products_screen.dart';
import '../../screens/purchase_detail_screen.dart';
import '../../screens/purchase_form_screen.dart';
import '../../screens/purchases_screen.dart';
import '../../screens/reset_password_screen.dart';
import '../../screens/sale_detail_screen.dart';
import '../../screens/sale_form_screen.dart';
import '../../screens/sales_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/stock_adjustment_screen.dart';
import '../../screens/stock_detail_screen.dart';
import '../../screens/stock_screen.dart';
import '../../widgets/auth_gate.dart';
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
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const dashboard = '/dashboard';
  static const companies = '/companies';
  static const companyForm = '/companies/form';
  static const companyDetail = '/companies/detail';
  static const products = '/products';
  static const productForm = '/products/form';
  static const productDetail = '/products/detail';
  static const purchases = '/purchases';
  static const purchaseForm = '/purchases/form';
  static const purchaseDetail = '/purchases/detail';
  static const sales = '/sales';
  static const saleForm = '/sales/form';
  static const saleDetail = '/sales/detail';
  static const stock = '/stock';
  static const stockDetail = '/stock/detail';
  static const stockAdjustment = '/stock/adjustment';
  static const reports = '/reports';
  static const settings = '/settings';

  static const publicRoutes = <String>{
    splash,
    login,
    forgotPassword,
    resetPassword,
  };

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
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? AppRoutes.splash;
    final args = settings.arguments;
    final page = switch (name) {
      AppRoutes.splash => const SplashScreen(),
      AppRoutes.login => const LoginScreen(),
      AppRoutes.forgotPassword => const ForgotPasswordScreen(),
      AppRoutes.resetPassword => const ResetPasswordScreen(),
      AppRoutes.dashboard => const AuthGate(child: DashboardScreen()),
      AppRoutes.companies => const AuthGate(child: CompaniesScreen()),
      AppRoutes.companyForm => AuthGate(
        child: CompanyFormScreen(companyId: args as String?),
      ),
      AppRoutes.companyDetail => AuthGate(
        child: CompanyDetailScreen(companyId: args as String),
      ),
      AppRoutes.products => const AuthGate(child: ProductsScreen()),
      AppRoutes.productForm => AuthGate(
        child: ProductFormScreen(productId: args as String?),
      ),
      AppRoutes.productDetail => AuthGate(
        child: ProductDetailScreen(productId: args as String),
      ),
      AppRoutes.purchases => const AuthGate(child: PurchasesScreen()),
      AppRoutes.purchaseForm => AuthGate(
        child: PurchaseFormScreen(purchaseId: args as String?),
      ),
      AppRoutes.purchaseDetail => AuthGate(
        child: PurchaseDetailScreen(purchaseId: args as String),
      ),
      AppRoutes.sales => const AuthGate(child: SalesScreen()),
      AppRoutes.saleForm => AuthGate(
        child: SaleFormScreen(saleId: args as String?),
      ),
      AppRoutes.saleDetail => AuthGate(
        child: SaleDetailScreen(saleId: args as String),
      ),
      AppRoutes.stock => const AuthGate(child: StockScreen()),
      AppRoutes.stockDetail => AuthGate(
        child: StockDetailScreen(productId: args as String),
      ),
      AppRoutes.stockAdjustment => AuthGate(
        child: StockAdjustmentScreen(productId: args as String?),
      ),
      AppRoutes.settings => const AuthGate(child: SettingsScreen()),
      _ => AuthGate(
        child: PlaceholderScreen(title: _titleFor(name), route: name),
      ),
    };

    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }

  static String _titleFor(String route) {
    for (final module in AppRoutes.modules) {
      if (module.route == route) return module.label;
    }
    return AppStrings.appName;
  }
}
