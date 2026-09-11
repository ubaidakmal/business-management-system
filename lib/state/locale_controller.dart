import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';

class LocaleController extends ChangeNotifier {
  LocaleController({LocaleService? service})
    : _service = service ?? LocaleService();

  final LocaleService _service;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh', 'TW'),
  ];

  Locale locale = const Locale('en');
  bool ready = false;

  AppLocalizations get l10n => lookupAppLocalizations(locale);

  String get languageCode {
    if (locale.languageCode == 'zh') return 'zh_TW';
    return 'en';
  }

  Future<void> load() async {
    final code = await _service.loadCode();
    locale = _localeFromCode(code);
    ready = true;
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    final next = _localeFromCode(code);
    if (next == locale) return;
    locale = next;
    notifyListeners();
    await _service.saveCode(code == 'zh_TW' ? 'zh_TW' : 'en');
  }

  static Locale _localeFromCode(String? code) {
    if (code == 'zh_TW' || code == 'zh-TW' || code == 'zh') {
      return const Locale('zh', 'TW');
    }
    return const Locale('en');
  }
}

class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found.');
    return scope!.notifier!;
  }

  static LocaleController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found.');
    return scope!.notifier!;
  }
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
