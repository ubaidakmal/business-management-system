import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_error.dart';
import '../core/utils/app_logger.dart';
import '../models/dashboard.dart';
import 'supabase_service.dart';

class DashboardService {
  SupabaseClient get _client => SupabaseService.client;

  Future<DashboardData> load({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? companyId,
  }) async {
    try {
      final raw = await _client.rpc(
        'get_dashboard_data',
        params: {
          'p_date_from': _dateOnly(dateFrom),
          'p_date_to': _dateOnly(dateTo),
          'p_company_id': companyId,
        },
      );

      if (raw is Map<String, dynamic>) {
        return DashboardData.fromJson(raw);
      }
      if (raw is Map) {
        return DashboardData.fromJson(Map<String, dynamic>.from(raw));
      }
      throw const AppException('Unexpected dashboard response.');
    } on PostgrestException catch (error) {
      AppLogger.error('Dashboard load failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    } on FunctionException catch (error) {
      AppLogger.error('Dashboard load failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  String _dateOnly(DateTime value) {
    final local = DateTime(value.year, value.month, value.day);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
