import 'package:flutter/foundation.dart';

import '../core/utils/app_error.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'app_status.dart';

class ProductsController extends ChangeNotifier {
  ProductsController({ProductService? service})
    : _service = service ?? ProductService();

  final ProductService _service;

  AppStatus status = AppStatus.initial;
  AppStatus actionStatus = AppStatus.initial;
  List<Product> items = const [];
  List<String> categories = const [];
  String query = '';
  String? companyId;
  String? category;
  bool? activeFilter;
  String? errorMessage;

  bool get isLoading => status.isLoading;

  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.list(
          query: query,
          companyId: companyId,
          category: category,
          isActive: activeFilter,
        ),
        _service.categories(),
      ]);
      items = results[0] as List<Product>;
      categories = results[1] as List<String>;
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
    activeFilter = value;
    await load();
  }

  Future<bool> setActive(Product product, bool isActive) async {
    actionStatus = AppStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final updated = await _service.setActive(
        id: product.id,
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

  Future<bool> delete(Product product) async {
    actionStatus = AppStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      await _service.delete(product.id);
      items = items.where((item) => item.id != product.id).toList();
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
