import 'package:flutter/material.dart';

import 'app.dart';
import 'core/utils/app_logger.dart';
import 'services/supabase_service.dart';
import 'state/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(details.exceptionAsString());
  };

  await SupabaseService.initialize();

  final auth = AuthController();
  await auth.start();

  runApp(AuthScope(controller: auth, child: const BusinessApp()));
}
