import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../core/utils/app_logger.dart';

abstract final class SupabaseService {
  static bool _ready = false;

  static bool get isReady => _ready;

  static Future<void> initialize() async {
    if (_ready) return;
    if (!AppConfig.hasSupabaseConfig) {
      AppLogger.info(
        'Supabase skipped. Set URL and anon key in lib/config/app_config.dart.',
      );
      return;
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
    _ready = true;
    AppLogger.info('Supabase initialized.');
  }

  static SupabaseClient get client {
    if (!_ready) {
      throw StateError(
        'Supabase is not ready. Set URL and anon key in lib/config/app_config.dart.',
      );
    }
    return Supabase.instance.client;
  }
}
