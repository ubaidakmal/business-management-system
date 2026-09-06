import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_error.dart';
import '../core/utils/app_logger.dart';
import '../models/stock_movement.dart';
import 'supabase_service.dart';

class StockService {
  SupabaseClient get _client => SupabaseService.client;

  Future<List<StockBalance>> listBalances({
    String query = '',
    String? companyId,
    String? category,
    bool? isActive,
    bool lowStockOnly = false,
  }) async {
    try {
      var builder = _client.from('product_stock_balances').select();

      if (companyId != null && companyId.isNotEmpty) {
        builder = builder.eq('company_id', companyId);
      }
      if (category != null && category.isNotEmpty) {
        builder = builder.eq('category', category);
      }
      if (isActive != null) {
        builder = builder.eq('is_active', isActive);
      }
      if (lowStockOnly) {
        builder = builder.eq('is_low_stock', true);
      }

      final trimmed = query.trim();
      if (trimmed.isNotEmpty) {
        builder = builder.or(
          'product_name.ilike.%$trimmed%,sku.ilike.%$trimmed%,company_name.ilike.%$trimmed%',
        );
      }

      final rows =
          await builder.order('product_name', ascending: true) as List<dynamic>;
      return rows
          .cast<Map<String, dynamic>>()
          .map(StockBalance.fromJson)
          .toList();
    } on PostgrestException catch (error) {
      AppLogger.error('Stock balance list failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<StockBalance> getBalance(String productId) async {
    try {
      final row = await _client
          .from('product_stock_balances')
          .select()
          .eq('product_id', productId)
          .maybeSingle();
      if (row == null) {
        throw const AppException('Product stock not found.');
      }
      return StockBalance.fromJson(row);
    } on PostgrestException catch (error) {
      AppLogger.error('Stock balance load failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<List<StockMovement>> listMovements(String productId) async {
    try {
      final rows =
          await _client
                  .from('stock_movements')
                  .select()
                  .eq('product_id', productId)
                  .order('created_at', ascending: false)
              as List<dynamic>;
      return rows
          .cast<Map<String, dynamic>>()
          .map(StockMovement.fromJson)
          .toList();
    } on PostgrestException catch (error) {
      AppLogger.error('Stock movements list failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<bool> hasMovements(String productId) async {
    try {
      final rows =
          await _client
                  .from('stock_movements')
                  .select('id')
                  .eq('product_id', productId)
                  .limit(1)
              as List<dynamic>;
      return rows.isNotEmpty;
    } on PostgrestException catch (error) {
      AppLogger.error('Stock movements check failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<List<String>> listCategories({String? companyId}) async {
    try {
      var builder = _client
          .from('products')
          .select('category')
          .not('category', 'is', null);
      if (companyId != null && companyId.isNotEmpty) {
        builder = builder.eq('company_id', companyId);
      }
      final rows = await builder as List<dynamic>;
      final values = <String>{};
      for (final row in rows.cast<Map<String, dynamic>>()) {
        final category = (row['category'] as String?)?.trim();
        if (category != null && category.isNotEmpty) values.add(category);
      }
      final list = values.toList()..sort();
      return list;
    } on PostgrestException catch (error) {
      AppLogger.error('Stock categories failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<String> createAdjustment({
    required String productId,
    required String direction,
    required double quantity,
    double? unitCost,
    String? reason,
    String? notes,
  }) async {
    try {
      final id = await _client.rpc(
        'create_stock_adjustment',
        params: {
          'p_product_id': productId,
          'p_direction': direction,
          'p_quantity': quantity,
          'p_unit_cost': unitCost,
          'p_reason': reason,
          'p_notes': notes,
        },
      );
      return id as String;
    } on PostgrestException catch (error) {
      AppLogger.error('Stock adjustment failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    } on FunctionException catch (error) {
      AppLogger.error('Stock adjustment failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }
}
