import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_error.dart';
import '../core/utils/app_logger.dart';
import '../models/product.dart';
import 'supabase_service.dart';

class ProductService {
  SupabaseClient get _client => SupabaseService.client;

  static const _select = '*, companies:company_id ( name )';

  Future<List<Product>> list({
    String query = '',
    String? companyId,
    String? category,
    bool? isActive,
  }) async {
    try {
      var builder = _client.from('products').select(_select);

      final trimmed = query.trim();
      if (trimmed.isNotEmpty) {
        builder = builder.or(
          'name.ilike.%$trimmed%,sku.ilike.%$trimmed%,barcode.ilike.%$trimmed%',
        );
      }
      if (companyId != null && companyId.isNotEmpty) {
        builder = builder.eq('company_id', companyId);
      }
      if (category != null && category.trim().isNotEmpty) {
        builder = builder.ilike('category', category.trim());
      }
      if (isActive != null) {
        builder = builder.eq('is_active', isActive);
      }

      final rows = await builder.order('name') as List<dynamic>;
      return rows.cast<Map<String, dynamic>>().map(Product.fromJson).toList();
    } on PostgrestException catch (error) {
      AppLogger.error('Product list failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<List<String>> categories() async {
    try {
      final rows =
          await _client
                  .from('products')
                  .select('category')
                  .not('category', 'is', null)
                  .order('category')
              as List<dynamic>;

      final values = <String>{};
      for (final row in rows.cast<Map<String, dynamic>>()) {
        final category = (row['category'] as String?)?.trim();
        if (category != null && category.isNotEmpty) values.add(category);
      }
      return values.toList()..sort();
    } on PostgrestException catch (error) {
      AppLogger.error('Product categories failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<Product> getById(String id) async {
    try {
      final row = await _client
          .from('products')
          .select(_select)
          .eq('id', id)
          .maybeSingle();
      if (row == null) {
        throw const AppException('Product not found.');
      }
      return Product.fromJson(row);
    } on PostgrestException catch (error) {
      AppLogger.error('Product load failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<Product> create(Product product) async {
    try {
      final payload = product.toJson();
      payload['created_by'] = _client.auth.currentUser?.id;
      final row = await _client
          .from('products')
          .insert(payload)
          .select(_select)
          .single();
      return Product.fromJson(row);
    } on PostgrestException catch (error) {
      AppLogger.error('Product create failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<Product> update(Product product) async {
    try {
      final row = await _client
          .from('products')
          .update(product.toJson())
          .eq('id', product.id)
          .select(_select)
          .single();
      return Product.fromJson(row);
    } on PostgrestException catch (error) {
      AppLogger.error('Product update failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<Product> setActive({
    required String id,
    required bool isActive,
  }) async {
    try {
      final row = await _client
          .from('products')
          .update({'is_active': isActive})
          .eq('id', id)
          .select(_select)
          .single();
      return Product.fromJson(row);
    } on PostgrestException catch (error) {
      AppLogger.error('Product status update failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('products').delete().eq('id', id);
    } on PostgrestException catch (error) {
      AppLogger.error('Product delete failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }
}
