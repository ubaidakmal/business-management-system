/// Public client values only. Never put a service-role key in this app.
///
/// Android Studio Play and `flutter run` both use these automatically.
abstract final class AppConfig {
  static const supabaseUrl = 'https://pkvvjicqbvbieltrgdov.supabase.co';
  static const supabaseAnonKey = 'sb_publishable_ytLPhQYHLhYgRveAGdjxEQ_MR4-dnOu';

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
