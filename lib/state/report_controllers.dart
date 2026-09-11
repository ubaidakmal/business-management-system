import 'package:flutter/foundation.dart';

import '../core/utils/app_error.dart';
import '../models/report.dart';
import '../models/stock_movement.dart';
import '../services/report_service.dart';
import '../services/stock_service.dart';
import 'app_status.dart';

mixin _DateCompanyFilters on ChangeNotifier {
  DateTime? dateFrom;
  DateTime? dateTo;
  String? companyId;

  Future<void> setDateRange({DateTime? from, DateTime? to}) async {
    dateFrom = from;
    dateTo = to;
    await load();
  }

  Future<void> setCompanyFilter(String? value) async {
    companyId = value;
    await load();
  }

  Future<void> load();
}

class SalesReportController extends ChangeNotifier with _DateCompanyFilters {
  SalesReportController({ReportService? service})
    : _service = service ?? ReportService();

  final ReportService _service;

  AppStatus status = AppStatus.initial;
  SalesReportData? data;
  String? errorMessage;
  String statusFilter = 'completed';
  String searchQuery = '';

  bool get isLoading => status.isLoading;

  @override
  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      data = await _service.salesReport(
        dateFrom: dateFrom,
        dateTo: dateTo,
        companyId: companyId,
        status: statusFilter,
        search: searchQuery,
      );
      status = data!.rows.isEmpty ? AppStatus.empty : AppStatus.success;
    } catch (error) {
      status = AppStatus.error;
      errorMessage = AppError.messageOf(error);
    }
    notifyListeners();
  }

  Future<void> setStatusFilter(String value) async {
    statusFilter = value;
    await load();
  }

  Future<void> search(String value) async {
    searchQuery = value;
    await load();
  }
}

class PurchasesReportController extends ChangeNotifier
    with _DateCompanyFilters {
  PurchasesReportController({ReportService? service})
    : _service = service ?? ReportService();

  final ReportService _service;

  AppStatus status = AppStatus.initial;
  PurchasesReportData? data;
  String? errorMessage;
  String searchQuery = '';

  bool get isLoading => status.isLoading;

  @override
  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      data = await _service.purchasesReport(
        dateFrom: dateFrom,
        dateTo: dateTo,
        companyId: companyId,
        search: searchQuery,
      );
      status = data!.rows.isEmpty ? AppStatus.empty : AppStatus.success;
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
}

class ProfitReportController extends ChangeNotifier with _DateCompanyFilters {
  ProfitReportController({ReportService? service})
    : _service = service ?? ReportService();

  final ReportService _service;

  AppStatus status = AppStatus.initial;
  ProfitReportData? data;
  String? errorMessage;
  String? productId;

  bool get isLoading => status.isLoading;

  @override
  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      data = await _service.profitReport(
        dateFrom: dateFrom,
        dateTo: dateTo,
        companyId: companyId,
        productId: productId,
      );
      status = data!.rows.isEmpty ? AppStatus.empty : AppStatus.success;
    } catch (error) {
      status = AppStatus.error;
      errorMessage = AppError.messageOf(error);
    }
    notifyListeners();
  }

  Future<void> setProductFilter(String? value) async {
    productId = value;
    await load();
  }
}

class ProductReportController extends ChangeNotifier with _DateCompanyFilters {
  ProductReportController({ReportService? service})
    : _service = service ?? ReportService();

  final ReportService _service;

  AppStatus status = AppStatus.initial;
  ProductReportData? data;
  String? errorMessage;

  bool get isLoading => status.isLoading;

  @override
  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      data = await _service.productReport(
        dateFrom: dateFrom,
        dateTo: dateTo,
        companyId: companyId,
      );
      status = data!.rows.isEmpty ? AppStatus.empty : AppStatus.success;
    } catch (error) {
      status = AppStatus.error;
      errorMessage = AppError.messageOf(error);
    }
    notifyListeners();
  }
}

class CompanyReportController extends ChangeNotifier {
  CompanyReportController({ReportService? service})
    : _service = service ?? ReportService();

  final ReportService _service;

  AppStatus status = AppStatus.initial;
  CompanyReportData? data;
  String? errorMessage;
  DateTime? dateFrom;
  DateTime? dateTo;

  bool get isLoading => status.isLoading;

  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      data = await _service.companyReport(dateFrom: dateFrom, dateTo: dateTo);
      status = data!.rows.isEmpty ? AppStatus.empty : AppStatus.success;
    } catch (error) {
      status = AppStatus.error;
      errorMessage = AppError.messageOf(error);
    }
    notifyListeners();
  }

  Future<void> setDateRange({DateTime? from, DateTime? to}) async {
    dateFrom = from;
    dateTo = to;
    await load();
  }
}

class StockReportController extends ChangeNotifier {
  StockReportController({StockService? service})
    : _service = service ?? StockService();

  final StockService _service;

  AppStatus status = AppStatus.initial;
  List<StockBalance> items = const [];
  String? errorMessage;
  String? companyId;
  String? category;
  bool lowStockOnly = false;
  bool outOfStockOnly = false;
  String searchQuery = '';
  List<String> categories = const [];

  bool get isLoading => status.isLoading;

  Future<void> bootstrap() async {
    try {
      categories = await _service.listCategories(companyId: companyId);
    } catch (_) {
      categories = const [];
    }
    await load();
  }

  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      var rows = await _service.listBalances(
        query: searchQuery,
        companyId: companyId,
        category: category,
        isActive: true,
        lowStockOnly: lowStockOnly && !outOfStockOnly,
      );
      if (outOfStockOnly) {
        rows = rows.where((r) => r.currentStock <= 0).toList();
      } else if (lowStockOnly) {
        rows = rows.where((r) => r.isLowStock && r.currentStock > 0).toList();
      }
      items = rows;
      status = items.isEmpty ? AppStatus.empty : AppStatus.success;
    } catch (error) {
      status = AppStatus.error;
      errorMessage = AppError.messageOf(error);
    }
    notifyListeners();
  }

  Future<void> setCompanyFilter(String? value) async {
    companyId = value;
    try {
      categories = await _service.listCategories(companyId: companyId);
    } catch (_) {
      categories = const [];
    }
    if (category != null && !categories.contains(category)) {
      category = null;
    }
    await load();
  }

  Future<void> setCategory(String? value) async {
    category = value;
    await load();
  }

  Future<void> setLowStockOnly(bool value) async {
    lowStockOnly = value;
    if (value) outOfStockOnly = false;
    await load();
  }

  Future<void> setOutOfStockOnly(bool value) async {
    outOfStockOnly = value;
    if (value) lowStockOnly = false;
    await load();
  }

  Future<void> search(String value) async {
    searchQuery = value;
    await load();
  }

  Future<List<StockMovement>> movementsFor(String productId) {
    return _service.listMovements(productId);
  }
}
