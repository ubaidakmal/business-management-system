/// UI permission helpers derived from profile role.
/// Database RLS / RPCs remain the security source of truth.
class AppPermissions {
  const AppPermissions(this.role);

  final String role;

  bool get isAdmin => role == 'admin';

  bool get viewReports => true;
  bool get manageProducts => true;
  bool get managePurchases => true;
  bool get manageSales => true;
  bool get manageStock => true;
  bool get viewSettings => true;
  bool get viewMarket => true;

  bool get manageUsers => isAdmin;
  bool get manageSettings => isAdmin;
  bool get viewAdmin => isAdmin;
  bool get hardDeleteMasterData => isAdmin;
  bool get adjustStock => isAdmin;
  bool get manageMarketSettings => isAdmin;

  static const permissionLabels = <String, String>{
    'view_reports': 'View reports',
    'manage_products': 'Manage products',
    'manage_purchases': 'Manage purchases',
    'manage_sales': 'Manage sales',
    'manage_stock': 'Manage stock',
    'view_settings': 'View settings',
    'view_market': 'View market data',
    'manage_users': 'Manage users',
    'manage_settings': 'Manage settings',
    'view_admin': 'Administration',
    'manage_market_settings': 'Manage market settings',
  };

  List<String> get grantedLabels {
    final labels = <String>[
      permissionLabels['view_reports']!,
      permissionLabels['manage_products']!,
      permissionLabels['manage_purchases']!,
      permissionLabels['manage_sales']!,
      permissionLabels['manage_stock']!,
      permissionLabels['view_settings']!,
      permissionLabels['view_market']!,
    ];
    if (isAdmin) {
      labels.addAll([
        permissionLabels['manage_users']!,
        permissionLabels['manage_settings']!,
        permissionLabels['view_admin']!,
        permissionLabels['manage_market_settings']!,
      ]);
    }
    return labels;
  }
}
