import 'package:flutter/material.dart';

import '../core/routes/app_router.dart';
import '../models/permission.dart';
import '../state/auth_controller.dart';
import 'app_states.dart';
import 'auth_gate.dart';

/// Requires authentication and admin role.
class AdminGate extends StatelessWidget {
  const AdminGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AuthGate(
      child: Builder(
        builder: (context) {
          final auth = AuthScope.of(context);
          final permissions = AppPermissions(auth.user?.role ?? 'user');
          if (!permissions.viewAdmin) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, AppRoutes.settings);
            });
            return const Scaffold(
              body: AppEmptyState(
                title: 'Admin only',
                message: 'You do not have permission to view administration.',
              ),
            );
          }
          return child;
        },
      ),
    );
  }
}
