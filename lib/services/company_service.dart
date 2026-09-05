import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_error.dart';
import '../core/utils/app_logger.dart';
import '../models/company.dart';
import 'supabase_service.dart';

class CompanyService {
  SupabaseClient get _client => SupabaseService.client;

  Future<List<Company>> list({String query = '', bool? isActive}) async {
    try {
      var builder = _client.from('companies').select();

      final trimmed = query.trim();
      if (trimmed.isNotEmpty) {
        builder = builder.or('name.ilike.%$trimmed%,code.ilike.%$trimmed%');
      }
      if (isActive != null) {
        builder = builder.eq('is_active', isActive);
      }

      final rows = await builder.order('name') as List<dynamic>;
      return rows.cast<Map<String, dynamic>>().map(Company.fromJson).toList();
    } on PostgrestException catch (error) {
      AppLogger.error('Company list failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<Company> getById(String id) async {
    try {
      final row = await _client
          .from('companies')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row == null) {
        throw const AppException('Company not found.');
      }
      return Company.fromJson(row);
    } on PostgrestException catch (error) {
      AppLogger.error('Company load failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<Company> create(Company company) async {
    try {
      final payload = company.toJson();
      payload['created_by'] = _client.auth.currentUser?.id;
      final row = await _client
          .from('companies')
          .insert(payload)
          .select()
          .single();
      return Company.fromJson(row);
    } on PostgrestException catch (error) {
      AppLogger.error('Company create failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<Company> update(Company company) async {
    try {
      final row = await _client
          .from('companies')
          .update(company.toJson())
          .eq('id', company.id)
          .select()
          .single();
      return Company.fromJson(row);
    } on PostgrestException catch (error) {
      AppLogger.error('Company update failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<Company> setActive({
    required String id,
    required bool isActive,
  }) async {
    try {
      final row = await _client
          .from('companies')
          .update({'is_active': isActive})
          .eq('id', id)
          .select()
          .single();
      return Company.fromJson(row);
    } on PostgrestException catch (error) {
      AppLogger.error('Company status update failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('companies').delete().eq('id', id);
    } on PostgrestException catch (error) {
      AppLogger.error('Company delete failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }
}
