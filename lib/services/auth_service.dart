import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../core/utils/app_error.dart';
import '../core/utils/app_logger.dart';
import '../models/app_user.dart';
import 'supabase_service.dart';

class AuthService {
  SupabaseClient get _client => SupabaseService.client;

  User? get currentUser =>
      SupabaseService.isReady ? _client.auth.currentUser : null;

  Session? get currentSession =>
      SupabaseService.isReady ? _client.auth.currentSession : null;

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      AppLogger.info('Signed in');
    } on AuthException catch (error) {
      AppLogger.error('Sign in failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    AppLogger.info('Signed out');
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: AppConfig.authRedirectUrl,
      );
      AppLogger.info('Password reset email requested');
    } on AuthException catch (error) {
      AppLogger.error('Password reset failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<void> updatePassword(String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
      AppLogger.info('Password updated');
    } on AuthException catch (error) {
      AppLogger.error('Password update failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<AppUser?> fetchProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // Missing/blocked profile must not become a fake active user.
      if (data == null) return null;
      return AppUser.fromJson(data);
    } on PostgrestException catch (error) {
      AppLogger.error('Profile load failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<AppUser> updateProfileName(String name) async {
    final user = currentUser;
    if (user == null) {
      throw const AppException('You must be signed in.');
    }

    try {
      final data = await _client
          .from('profiles')
          .update({'name': name.trim()})
          .eq('id', user.id)
          .select()
          .single();
      return AppUser.fromJson(data);
    } on PostgrestException catch (error) {
      AppLogger.error('Profile update failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }
}
