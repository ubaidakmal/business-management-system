import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_error.dart';
import '../core/utils/app_logger.dart';
import '../models/app_settings.dart';
import 'supabase_service.dart';

class SettingsService {
  SettingsService();

  static AppSettings? _cache;

  SupabaseClient get _client => SupabaseService.client;

  static AppSettings get cached => _cache ?? AppSettings.defaults;

  static String get cachedBusinessName => cached.businessName;

  static void clearCache() => _cache = null;

  Future<AppSettings> load({bool force = false}) async {
    if (!force && _cache != null) return _cache!;
    try {
      final row = await _client
          .from('app_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();
      final settings = row == null
          ? AppSettings.defaults
          : AppSettings.fromJson(row);
      _cache = settings;
      return settings;
    } on PostgrestException catch (error) {
      AppLogger.error('Settings load failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<AppSettings> save(AppSettings settings) async {
    try {
      final row = await _client
          .from('app_settings')
          .update(settings.toUpdateJson())
          .eq('id', 1)
          .select()
          .single();
      final saved = AppSettings.fromJson(row);
      _cache = saved;
      return saved;
    } on PostgrestException catch (error) {
      AppLogger.error('Settings save failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<AdminOverview> adminOverview() async {
    try {
      final raw = await _client.rpc('get_admin_overview');
      if (raw is Map<String, dynamic>) {
        return AdminOverview.fromJson(raw);
      }
      if (raw is Map) {
        return AdminOverview.fromJson(Map<String, dynamic>.from(raw));
      }
      return AdminOverview.empty;
    } on PostgrestException catch (error) {
      AppLogger.error('Admin overview failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    } on FunctionException catch (error) {
      AppLogger.error('Admin overview failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }
}
