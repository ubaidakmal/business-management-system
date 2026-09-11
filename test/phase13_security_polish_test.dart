import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:business_management_app/core/utils/app_error.dart';
import 'package:business_management_app/models/permission.dart';
import 'package:business_management_app/state/auth_controller.dart';
import 'package:business_management_app/state/app_status.dart';

void main() {
  group('AppPermissions security surface', () {
    test('admin-only flags stay admin-only', () {
      final admin = AppPermissions('admin');
      final user = AppPermissions('user');

      expect(admin.hardDeleteMasterData, isTrue);
      expect(admin.adjustStock, isTrue);
      expect(admin.manageMarketSettings, isTrue);
      expect(admin.viewMarket, isTrue);

      expect(user.hardDeleteMasterData, isFalse);
      expect(user.adjustStock, isFalse);
      expect(user.manageMarketSettings, isFalse);
      expect(user.viewMarket, isTrue);
      expect(user.viewReports, isTrue);
    });
  });

  group('AppError', () {
    test('maps Edge Function {error} payload', () {
      final error = FunctionException(
        status: 502,
        details: {'error': 'Market API request timed out.'},
        reasonPhrase: 'Bad Gateway',
      );
      expect(AppError.messageOf(error), 'Market API request timed out.');
    });

    test('maps network-like type names', () {
      expect(
        AppError.messageOf(Exception('ClientException: failed')),
        'Something went wrong. Please try again.',
      );
    });
  });

  group('AuthController polish', () {
    test('unauthenticated factory starts signed out', () {
      final auth = AuthController.unauthenticated();
      expect(auth.status, AuthStatus.unauthenticated);
      expect(auth.user, isNull);
      expect(auth.isAuthenticated, isFalse);
    });

    test('clearError resets error action status', () {
      final auth = AuthController.unauthenticated();
      auth.errorMessage = 'This account is disabled. Contact an administrator.';
      auth.actionStatus = AppStatus.error;
      auth.clearError();
      expect(auth.errorMessage, isNull);
      expect(auth.actionStatus, AppStatus.initial);
    });
  });
}
