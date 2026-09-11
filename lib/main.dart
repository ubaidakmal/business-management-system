import 'package:flutter/material.dart';

import 'app.dart';
import 'core/constants/app_strings.dart';
import 'core/utils/app_logger.dart';
import 'services/supabase_service.dart';
import 'state/auth_controller.dart';
import 'state/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(details.exceptionAsString());
  };

  await SupabaseService.initialize();

  final locale = LocaleController();
  await locale.load();
  AppStrings.bind(() => locale.l10n);

  final auth = AuthController();
  await auth.start();

  runApp(
    LocaleScope(
      controller: locale,
      child: AuthScope(controller: auth, child: const BusinessApp()),
    ),
  );
}
