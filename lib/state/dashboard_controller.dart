import 'package:flutter/foundation.dart';

import '../core/utils/app_error.dart';
import '../models/dashboard.dart';
import '../services/dashboard_service.dart';
import 'app_status.dart';

enum DashboardRangePreset { today, week, month, custom }

class DashboardController extends ChangeNotifier {
  DashboardController({DashboardService? service})
    : _service = service ?? DashboardService();

  final DashboardService _service;

  AppStatus status = AppStatus.initial;
  DashboardData? data;
  String? errorMessage;
  String? companyId;
  DashboardRangePreset preset = DashboardRangePreset.month;
  DateTime dateFrom = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime dateTo = DateTime.now();

  bool get isLoading => status.isLoading;

  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      data = await _service.load(
        dateFrom: dateFrom,
        dateTo: dateTo,
        companyId: companyId,
      );
      status = AppStatus.success;
    } catch (error) {
      status = AppStatus.error;
      errorMessage = AppError.messageOf(error);
    }
    notifyListeners();
  }

  Future<void> setCompanyFilter(String? value) async {
    companyId = value;
    await load();
  }

  Future<void> setPreset(DashboardRangePreset value) async {
    preset = value;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (value) {
      case DashboardRangePreset.today:
        dateFrom = today;
        dateTo = today;
        break;
      case DashboardRangePreset.week:
        dateFrom = today.subtract(Duration(days: today.weekday - 1));
        dateTo = today;
        break;
      case DashboardRangePreset.month:
        dateFrom = DateTime(today.year, today.month, 1);
        dateTo = today;
        break;
      case DashboardRangePreset.custom:
        break;
    }
    await load();
  }

  Future<void> setCustomRange({
    required DateTime from,
    required DateTime to,
  }) async {
    preset = DashboardRangePreset.custom;
    dateFrom = DateTime(from.year, from.month, from.day);
    dateTo = DateTime(to.year, to.month, to.day);
    await load();
  }
}
