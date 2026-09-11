import 'package:flutter/foundation.dart';

import '../core/utils/app_error.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import 'app_status.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({SettingsService? service})
    : _service = service ?? SettingsService();

  final SettingsService _service;

  AppStatus status = AppStatus.initial;
  AppStatus saveStatus = AppStatus.initial;
  AppSettings settings = AppSettings.defaults;
  String? errorMessage;
  String? saveMessage;

  bool get isLoading => status.isLoading;
  bool get isSaving => saveStatus.isLoading;

  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      settings = await _service.load(force: true);
      status = AppStatus.success;
    } catch (error) {
      status = AppStatus.error;
      errorMessage = AppError.messageOf(error);
      settings = SettingsService.cached;
    }
    notifyListeners();
  }

  Future<bool> saveBusiness(AppSettings next) async {
    saveStatus = AppStatus.loading;
    saveMessage = null;
    errorMessage = null;
    notifyListeners();
    try {
      settings = await _service.save(next);
      saveStatus = AppStatus.success;
      saveMessage = 'Business settings saved.';
      notifyListeners();
      return true;
    } catch (error) {
      saveStatus = AppStatus.error;
      errorMessage = AppError.messageOf(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> savePreferences(AppSettings next) async {
    return saveBusiness(next);
  }
}

class AdminOverviewController extends ChangeNotifier {
  AdminOverviewController({SettingsService? service})
    : _service = service ?? SettingsService();

  final SettingsService _service;

  AppStatus status = AppStatus.initial;
  AdminOverview overview = AdminOverview.empty;
  String? errorMessage;

  bool get isLoading => status.isLoading;

  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      overview = await _service.adminOverview();
      status = AppStatus.success;
    } catch (error) {
      status = AppStatus.error;
      errorMessage = AppError.messageOf(error);
    }
    notifyListeners();
  }
}
