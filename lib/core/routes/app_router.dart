import 'package:flutter/material.dart';

import '../../screens/admin/admin_overview_screen.dart';
import '../../screens/admin/admin_user_detail_screen.dart';
import '../../screens/admin/admin_users_screen.dart';
import '../../screens/companies_screen.dart';
import '../../screens/company_detail_screen.dart';
import '../../screens/company_form_screen.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/forgot_password_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/market/market_screen.dart';
import '../../screens/placeholder_screen.dart';
import '../../screens/product_detail_screen.dart';
import '../../screens/product_form_screen.dart';
import '../../screens/products_screen.dart';
import '../../screens/purchase_detail_screen.dart';
import '../../screens/purchase_form_screen.dart';
import '../../screens/purchases_screen.dart';
import '../../screens/reports/company_report_screen.dart';
import '../../screens/reports/product_report_screen.dart';
import '../../screens/reports/profit_report_screen.dart';
import '../../screens/reports/purchases_report_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/reports/sales_report_screen.dart';
import '../../screens/reports/stock_report_screen.dart';
import '../../screens/reset_password_screen.dart';
import '../../screens/sale_detail_screen.dart';
import '../../screens/sale_form_screen.dart';
import '../../screens/sales_screen.dart';
import '../../screens/settings/business_settings_screen.dart';
import '../../screens/settings/market_settings_screen.dart';
import '../../screens/settings/permissions_settings_screen.dart';
import '../../screens/settings/preferences_settings_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/stock_adjustment_screen.dart';
import '../../screens/stock_detail_screen.dart';
import '../../screens/stock_screen.dart';
import '../../widgets/auth_gate.dart';
import '../constants/app_strings.dart';
import '../../l10n/app_localizations.dart';

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
  static const market = '/market';
  static const reports = '/reports';
  static const reportsSales = '/reports/sales';
  static const reportsPurchases = '/reports/purchases';
  static const reportsProfit = '/reports/profit';
  static const reportsStock = '/reports/stock';
  static const reportsProducts = '/reports/products';
  static const reportsCompanies = '/reports/companies';
  static const settings = '/settings';
  static const settingsBusiness = '/settings/business';
  static const settingsPreferences = '/settings/preferences';
  static const settingsPermissions = '/settings/permissions';
  static const settingsMarket = '/settings/market';
  static const admin = '/admin';
  static const adminUsers = '/admin/users';
  static const adminUserDetail = '/admin/users/detail';

  static const publicRoutes = <String>{
    splash,
    login,
    forgotPassword,
    resetPassword,
  };

  static List<AppDestination> modules(AppLocalizations l10n) => [
    AppDestination(
      route: dashboard,
      label: l10n.navDashboard,
      icon: Icons.space_dashboard_outlined,
    ),
    AppDestination(
      route: companies,
      label: l10n.navCompanies,
      icon: Icons.apartment_outlined,
    ),
    AppDestination(
      route: products,
      label: l10n.navProducts,
      icon: Icons.inventory_2_outlined,
    ),
    AppDestination(
      route: purchases,
      label: l10n.navPurchases,
      icon: Icons.shopping_cart_outlined,
    ),
    AppDestination(
      route: sales,
      label: l10n.navSales,
      icon: Icons.point_of_sale_outlined,
    ),
    AppDestination(
      route: stock,
      label: l10n.navStock,
      icon: Icons.warehouse_outlined,
    ),
    AppDestination(
      route: market,
      label: l10n.navMarket,
      icon: Icons.show_chart_outlined,
    ),
    AppDestination(
      route: reports,
      label: l10n.navReports,
      icon: Icons.bar_chart_outlined,
    ),
    AppDestination(
      route: settings,
      label: l10n.navSettings,
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
      AppRoutes.market => const AuthGate(child: MarketScreen()),
      AppRoutes.reports => const AuthGate(child: ReportsScreen()),
      AppRoutes.reportsSales => const AuthGate(child: SalesReportScreen()),
      AppRoutes.reportsPurchases => const AuthGate(
        child: PurchasesReportScreen(),
      ),
      AppRoutes.reportsProfit => const AuthGate(child: ProfitReportScreen()),
      AppRoutes.reportsStock => const AuthGate(child: StockReportScreen()),
      AppRoutes.reportsProducts => const AuthGate(child: ProductReportScreen()),
      AppRoutes.reportsCompanies => const AuthGate(
        child: CompanyReportScreen(),
      ),
      AppRoutes.settings => const AuthGate(child: SettingsScreen()),
      AppRoutes.settingsBusiness => const BusinessSettingsScreen(),
      AppRoutes.settingsPreferences => const PreferencesSettingsScreen(),
      AppRoutes.settingsPermissions => const AuthGate(
        child: PermissionsSettingsScreen(),
      ),
      AppRoutes.settingsMarket => const MarketSettingsScreen(),
      AppRoutes.admin => const AdminOverviewScreen(),
      AppRoutes.adminUsers => const AdminUsersScreen(),
      AppRoutes.adminUserDetail => AdminUserDetailScreen(
        userId: args as String,
      ),
      _ => AuthGate(
        child: PlaceholderScreen(title: _titleFor(name), route: name),
      ),
    };

    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }

  static String _titleFor(String route) {
    final l10n = lookupAppLocalizations(const Locale('en'));
    for (final module in AppRoutes.modules(l10n)) {
      if (module.route == route) return module.label;
    }
    return AppStrings.appName;
  }
}
