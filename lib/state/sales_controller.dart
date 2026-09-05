import 'package:flutter/foundation.dart';

import '../core/utils/app_error.dart';
import '../models/sale.dart';
import '../services/sale_service.dart';
import 'app_status.dart';

class SalesController extends ChangeNotifier {
  SalesController({SaleService? service}) : _service = service ?? SaleService();

  final SaleService _service;

  AppStatus status = AppStatus.initial;
  AppStatus actionStatus = AppStatus.initial;
  List<Sale> items = const [];
  String query = '';
  String? companyId;
  String? statusFilter;
  DateTime? dateFrom;
  DateTime? dateTo;
  String? errorMessage;

  bool get isLoading => status.isLoading;

  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      items = await _service.list(
        query: query,
        companyId: companyId,
        status: statusFilter,
        dateFrom: dateFrom,
        dateTo: dateTo,
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

  Future<void> setStatusFilter(String? value) async {
    statusFilter = value;
    await load();
  }

  Future<void> setDateRange({DateTime? from, DateTime? to}) async {
    dateFrom = from;
    dateTo = to;
    await load();
  }

  Future<bool> cancel(Sale sale) async {
    actionStatus = AppStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      await _service.cancel(sale.id);
      await load();
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
