import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_error.dart';
import '../core/utils/app_logger.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/supabase_service.dart';
import 'app_status.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController({AuthService? authService})
    : _auth = authService ?? AuthService();

  /// Used by widget tests — no Supabase calls.
  AuthController.unauthenticated()
    : _auth = AuthService(),
      status = AuthStatus.unauthenticated;

  final AuthService _auth;
  StreamSubscription<AuthState>? _subscription;

  AuthStatus status = AuthStatus.checking;
  AppStatus actionStatus = AppStatus.initial;
  AppUser? user;
  String? errorMessage;
  bool passwordRecovery = false;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => actionStatus.isLoading;

  Future<void> start() async {
    if (!SupabaseService.isReady) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _subscription ??= _auth.authChanges.listen(_onAuthChange);
    await restoreSession();
  }

  Future<void> restoreSession() async {
    status = AuthStatus.checking;
    errorMessage = null;
    notifyListeners();

    if (!SupabaseService.isReady || _auth.currentSession == null) {
      status = AuthStatus.unauthenticated;
      user = null;
      notifyListeners();
      return;
    }

    await _loadProfile();
  }

  Future<bool> signIn({required String email, required String password}) async {
    actionStatus = AppStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      await _auth.signIn(email: email, password: password);
      await _loadProfile();
      if (status != AuthStatus.authenticated) {
        actionStatus = AppStatus.error;
        errorMessage ??= 'Sign in failed.';
        notifyListeners();
        return false;
      }
      actionStatus = AppStatus.success;
      notifyListeners();
      return true;
    } catch (error) {
      actionStatus = AppStatus.error;
      errorMessage = AppError.messageOf(error);
      status = AuthStatus.unauthenticated;
      user = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    actionStatus = AppStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      if (SupabaseService.isReady) {
        await _auth.signOut();
      }
    } catch (error) {
      AppLogger.error('Sign out failed', error);
    } finally {
      passwordRecovery = false;
      user = null;
      SettingsService.clearCache();
      status = AuthStatus.unauthenticated;
      actionStatus = AppStatus.success;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    actionStatus = AppStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      await _auth.sendPasswordReset(email);
      actionStatus = AppStatus.success;
      notifyListeners();
      return true;
    } catch (error) {
      actionStatus = AppStatus.error;
      errorMessage = AppError.messageOf(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String password) async {
    actionStatus = AppStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      await _auth.updatePassword(password);
      passwordRecovery = false;
      actionStatus = AppStatus.success;
      notifyListeners();
      return true;
    } catch (error) {
      actionStatus = AppStatus.error;
      errorMessage = AppError.messageOf(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateName(String name) async {
    actionStatus = AppStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      user = await _auth.updateProfileName(name);
      actionStatus = AppStatus.success;
      notifyListeners();
      return true;
    } catch (error) {
      actionStatus = AppStatus.error;
      errorMessage = AppError.messageOf(error);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    if (actionStatus == AppStatus.error) {
      actionStatus = AppStatus.initial;
    }
    notifyListeners();
  }

  Future<void> _onAuthChange(AuthState state) async {
    AppLogger.info('Auth event: ${state.event.name}');

    if (state.event == AuthChangeEvent.passwordRecovery) {
      passwordRecovery = true;
      notifyListeners();
      return;
    }

    if (state.event == AuthChangeEvent.signedOut) {
      passwordRecovery = false;
      user = null;
      SettingsService.clearCache();
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    if (state.session != null &&
        (state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.tokenRefreshed ||
            state.event == AuthChangeEvent.initialSession ||
            state.event == AuthChangeEvent.userUpdated)) {
      await _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    try {
      user = await _auth.fetchProfile();
      if (user != null && !user!.isActive) {
        await _auth.signOut();
        user = null;
        status = AuthStatus.unauthenticated;
        errorMessage = 'This account is disabled. Contact an administrator.';
        actionStatus = AppStatus.error;
        notifyListeners();
        return;
      }
      status = user == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
      if (status == AuthStatus.authenticated) {
        unawaited(SettingsService().load());
      }
    } catch (error) {
      AppLogger.error('Could not load profile', error);
      // Session exists — keep the user authenticated with auth email fallback.
      final authUser = _auth.currentUser;
      if (authUser != null) {
        user = AppUser(
          id: authUser.id,
          email: authUser.email ?? '',
          name: authUser.email?.split('@').first,
        );
        status = AuthStatus.authenticated;
        unawaited(SettingsService().load());
      } else {
        status = AuthStatus.unauthenticated;
        user = null;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found. Wrap the app with AuthScope.');
    return scope!.notifier!;
  }

  static AuthController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found. Wrap the app with AuthScope.');
    return scope!.notifier!;
  }
}
