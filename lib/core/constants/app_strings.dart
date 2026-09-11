import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Localized UI strings.
/// Prefer `context.l10n` in new code. These getters follow [LocaleController].
abstract final class AppStrings {
  static AppLocalizations Function()? _resolver;

  static void bind(AppLocalizations Function() resolver) {
    _resolver = resolver;
  }

  static AppLocalizations get _l =>
      _resolver?.call() ?? lookupAppLocalizations(const Locale('en'));

  static String get appName => _l.appName;
  static String get tagline => _l.tagline;
  static String get splashMessage => _l.splashMessage;
  static String get loginTitle => _l.loginTitle;
  static String get loginSubtitle => _l.loginSubtitle;
  static String get emailLabel => _l.emailLabel;
  static String get passwordLabel => _l.passwordLabel;
  static String get confirmPasswordLabel => _l.confirmPasswordLabel;
  static String get signIn => _l.signIn;
  static String get signOut => _l.signOut;
  static String get forgotPassword => _l.forgotPassword;
  static String get forgotPasswordTitle => _l.forgotPasswordTitle;
  static String get forgotPasswordSubtitle => _l.forgotPasswordSubtitle;
  static String get sendResetLink => _l.sendResetLink;
  static String get resetEmailSent => _l.resetEmailSent;
  static String get backToLogin => _l.backToLogin;
  static String get newPasswordTitle => _l.newPasswordTitle;
  static String get newPasswordSubtitle => _l.newPasswordSubtitle;
  static String get updatePassword => _l.updatePassword;
  static String get passwordUpdated => _l.passwordUpdated;
  static String get nameLabel => _l.nameLabel;
  static String get roleLabel => _l.roleLabel;
  static String get profileTitle => _l.profileTitle;
  static String get saveProfile => _l.saveProfile;
  static String get profileUpdated => _l.profileUpdated;
  static String get welcome => _l.welcome;
  static String get phasePlaceholder => _l.phasePlaceholder;
  static String get retry => _l.retry;
  static String get loading => _l.loading;
  static String get emptyTitle => _l.emptyTitle;
  static String get errorTitle => _l.errorTitle;
  static String get sessionExpired => _l.sessionExpired;
}
