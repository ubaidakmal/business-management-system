import 'package:shared_preferences/shared_preferences.dart';

/// Local-only language preference. Never synced to Supabase.
class LocaleService {
  static const preferenceKey = 'app_locale_code';

  /// Supported codes: `en`, `zh_TW`. Default English.
  Future<String?> loadCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(preferenceKey);
  }

  Future<void> saveCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(preferenceKey, code);
  }
}
