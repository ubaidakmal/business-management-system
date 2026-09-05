import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/routes/app_router.dart';
import '../state/auth_controller.dart';
import '../widgets/app_states.dart';

/// Redirects unauthenticated users to login. Public auth screens skip this.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    if (auth.status == AuthStatus.checking) {
      return const Scaffold(
        body: AppLoading(message: AppStrings.splashMessage),
      );
    }

    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        );
      });
      return const Scaffold(
        body: AppLoading(message: AppStrings.sessionExpired),
      );
    }

    return child;
  }
}
