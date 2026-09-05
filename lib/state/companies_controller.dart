import 'package:flutter/foundation.dart';

import '../core/utils/app_error.dart';
import '../models/company.dart';
import '../services/company_service.dart';
import 'app_status.dart';

class CompaniesController extends ChangeNotifier {
  CompaniesController({CompanyService? service})
    : _service = service ?? CompanyService();

  final CompanyService _service;

  AppStatus status = AppStatus.initial;
  AppStatus actionStatus = AppStatus.initial;
  List<Company> items = const [];
  String query = '';
  bool? activeFilter;
  String? errorMessage;
  bool get isLoading => status.isLoading;
  bool get isSaving => actionStatus.isLoading;

  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      items = await _service.list(query: query, isActive: activeFilter);
      status = items.isEmpty ? AppStatus.empty : AppStatus.success;
    } catch (error) {
      status = AppStatus.error;
      errorMessage = AppError.messageOf(error);
    }
    notifyListeners();
  }

  Future<void> search(String value) async {
    query = value;
    await load();
  }

  Future<void> setActiveFilter(bool? value) async {
    activeFilter = value;
    await load();
  }

  Future<bool> setActive(Company company, bool isActive) async {
    actionStatus = AppStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final updated = await _service.setActive(
        id: company.id,
        isActive: isActive,
      );
      items = [
        for (final item in items)
          if (item.id == updated.id) updated else item,
      ];
      if (activeFilter != null) {
        items = items.where((item) => item.isActive == activeFilter).toList();
      }
      status = items.isEmpty ? AppStatus.empty : AppStatus.success;
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

  Future<bool> delete(Company company) async {
    actionStatus = AppStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      await _service.delete(company.id);
      items = items.where((item) => item.id != company.id).toList();
      status = items.isEmpty ? AppStatus.empty : AppStatus.success;
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
}
