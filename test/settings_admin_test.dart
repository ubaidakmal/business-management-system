import 'package:flutter_test/flutter_test.dart';

import 'package:business_management_app/models/app_settings.dart';
import 'package:business_management_app/models/app_user.dart';
import 'package:business_management_app/models/permission.dart';

void main() {
  test('AppUser.fromJson maps is_active and role', () {
    final user = AppUser.fromJson({
      'id': 'u1',
      'email': 'a@b.com',
      'name': 'Ada',
      'role': 'admin',
      'is_active': false,
    });

    expect(user.isAdmin, isTrue);
    expect(user.isActive, isFalse);
  });

  test('AppPermissions grants admin-only capabilities to admins', () {
    final admin = AppPermissions('admin');
    final user = AppPermissions('user');

    expect(admin.manageUsers, isTrue);
    expect(admin.manageSettings, isTrue);
    expect(user.manageUsers, isFalse);
    expect(user.viewReports, isTrue);
    expect(admin.grantedLabels, contains('Manage users'));
    expect(user.grantedLabels, isNot(contains('Manage users')));
  });

  test('AppSettings.fromJson and toUpdateJson round-trip fields', () {
    final settings = AppSettings.fromJson({
      'business_name': 'Acme Co',
      'contact_email': 'ops@acme.com',
      'default_currency': 'USD',
      'date_format': 'dd/MM/yyyy',
      'number_format': '1.234,56',
    });

    expect(settings.businessName, 'Acme Co');
    final json = settings.toUpdateJson();
    expect(json['business_name'], 'Acme Co');
    expect(json['default_currency'], 'USD');
  });

  test('AdminOverview.fromJson maps counts', () {
    final overview = AdminOverview.fromJson({
      'users_total': 3,
      'users_active': 2,
      'users_admins': 1,
      'companies_total': 5,
      'companies_active': 4,
      'products_total': 10,
      'products_active': 9,
    });

    expect(overview.usersTotal, 3);
    expect(overview.productsActive, 9);
  });
}
