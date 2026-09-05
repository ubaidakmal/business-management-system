import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/routes/app_router.dart';
import '../services/supabase_service.dart';
import '../state/auth_controller.dart';
import '../widgets/app_states.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final auth = AuthScope.read(context);
    if (auth.status == AuthStatus.checking) {
      await auth.restoreSession();
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (auth.passwordRecovery) {
      Navigator.pushReplacementNamed(context, AppRoutes.resetPassword);
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      auth.isAuthenticated ? AppRoutes.dashboard : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppLoading(
        message: SupabaseService.isReady
            ? AppStrings.splashMessage
            : 'Supabase is not configured yet.',
      ),
    );
  }
}
