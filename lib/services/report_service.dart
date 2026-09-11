import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_error.dart';
import '../core/utils/app_logger.dart';
import '../models/report.dart';
import 'supabase_service.dart';

class ReportService {
  SupabaseClient get _client => SupabaseService.client;

  Future<SalesReportData> salesReport({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? companyId,
    String status = 'completed',
    String search = '',
  }) async {
    final raw = await _rpc(
      'get_sales_report',
      params: {
        'p_date_from': _dateOnly(dateFrom),
        'p_date_to': _dateOnly(dateTo),
        'p_company_id': companyId,
        'p_status': status,
        'p_search': search.trim().isEmpty ? null : search.trim(),
      },
    );
    return SalesReportData.fromJson(raw);
  }

  Future<PurchasesReportData> purchasesReport({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? companyId,
    String search = '',
  }) async {
    final raw = await _rpc(
      'get_purchases_report',
      params: {
        'p_date_from': _dateOnly(dateFrom),
        'p_date_to': _dateOnly(dateTo),
        'p_company_id': companyId,
        'p_search': search.trim().isEmpty ? null : search.trim(),
      },
    );
    return PurchasesReportData.fromJson(raw);
  }

  Future<ProfitReportData> profitReport({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? companyId,
    String? productId,
  }) async {
    final raw = await _rpc(
      'get_profit_report',
      params: {
        'p_date_from': _dateOnly(dateFrom),
        'p_date_to': _dateOnly(dateTo),
        'p_company_id': companyId,
        'p_product_id': productId,
      },
    );
    return ProfitReportData.fromJson(raw);
  }

  Future<ProductReportData> productReport({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? companyId,
  }) async {
    final raw = await _rpc(
      'get_product_report',
      params: {
        'p_date_from': _dateOnly(dateFrom),
        'p_date_to': _dateOnly(dateTo),
        'p_company_id': companyId,
      },
    );
    return ProductReportData.fromJson(raw);
  }

  Future<CompanyReportData> companyReport({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final raw = await _rpc(
      'get_company_report',
      params: {
        'p_date_from': _dateOnly(dateFrom),
        'p_date_to': _dateOnly(dateTo),
      },
    );
    return CompanyReportData.fromJson(raw);
  }

  Future<Map<String, dynamic>> _rpc(
    String name, {
    required Map<String, dynamic> params,
  }) async {
    try {
      final raw = await _client.rpc(name, params: params);
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      throw const AppException('Unexpected report response.');
    } on PostgrestException catch (error) {
      AppLogger.error('Report $name failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    } on FunctionException catch (error) {
      AppLogger.error('Report $name failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    final local = DateTime(value.year, value.month, value.day);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
