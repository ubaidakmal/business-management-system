import 'package:flutter/foundation.dart';

import '../core/utils/app_error.dart';
import '../models/app_user.dart';
import '../services/user_management_service.dart';
import 'app_status.dart';

class UsersController extends ChangeNotifier {
  UsersController({UserManagementService? service})
    : _service = service ?? UserManagementService();

  final UserManagementService _service;

  AppStatus status = AppStatus.initial;
  AppStatus actionStatus = AppStatus.initial;
  List<AppUser> items = const [];
  String? errorMessage;
  String searchQuery = '';
  String? roleFilter;
  bool? activeFilter;

  bool get isLoading => status.isLoading;

  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      items = await _service.listUsers(
        query: searchQuery,
        role: roleFilter,
        isActive: activeFilter,
      );
      status = items.isEmpty ? AppStatus.empty : AppStatus.success;
    } catch (error) {
      status = AppStatus.error;
      errorMessage = AppError.messageOf(error);
    }
    notifyListeners();
  }

  Future<void> search(String value) async {
    searchQuery = value;
    await load();
  }

  Future<void> setRoleFilter(String? value) async {
    roleFilter = value;
    await load();
  }

  Future<void> setActiveFilter(bool? value) async {
    activeFilter = value;
    await load();
  }

  Future<AppUser?> updateUser({
    required String id,
    String? name,
    String? role,
    bool? isActive,
  }) async {
    actionStatus = AppStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final updated = await _service.updateUser(
        id: id,
        name: name,
        role: role,
        isActive: isActive,
      );
      actionStatus = AppStatus.success;
      await load();
      return updated;
    } catch (error) {
      actionStatus = AppStatus.error;
      errorMessage = AppError.messageOf(error);
      notifyListeners();
      return null;
    }
  }
}
