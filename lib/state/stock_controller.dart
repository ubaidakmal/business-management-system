import 'package:flutter/foundation.dart';

import '../core/utils/app_error.dart';
import '../models/stock_movement.dart';
import '../services/stock_service.dart';
import 'app_status.dart';

class StockController extends ChangeNotifier {
  StockController({StockService? service})
    : _service = service ?? StockService();

  final StockService _service;

  AppStatus status = AppStatus.initial;
  List<StockBalance> items = const [];
  String query = '';
  String? companyId;
  String? category;
  bool? isActive = true;
  bool lowStockOnly = false;
  String? errorMessage;

  bool get isLoading => status.isLoading;

  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      items = await _service.listBalances(
        query: query,
        companyId: companyId,
        category: category,
        isActive: isActive,
        lowStockOnly: lowStockOnly,
      );
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

  Future<void> setCompanyFilter(String? value) async {
    companyId = value;
    await load();
  }

  Future<void> setCategoryFilter(String? value) async {
    category = value;
    await load();
  }

  Future<void> setActiveFilter(bool? value) async {
    isActive = value;
    await load();
  }

  Future<void> setLowStockOnly(bool value) async {
    lowStockOnly = value;
    await load();
  }
}
