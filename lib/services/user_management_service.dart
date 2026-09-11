import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_error.dart';
import '../core/utils/app_logger.dart';
import '../models/app_user.dart';
import 'supabase_service.dart';

class UserManagementService {
  SupabaseClient get _client => SupabaseService.client;

  Future<List<AppUser>> listUsers({
    String query = '',
    String? role,
    bool? isActive,
  }) async {
    try {
      var builder = _client.from('profiles').select();
      if (role != null && role.isNotEmpty) {
        builder = builder.eq('role', role);
      }
      if (isActive != null) {
        builder = builder.eq('is_active', isActive);
      }
      final trimmed = query.trim();
      if (trimmed.isNotEmpty) {
        builder = builder.or('email.ilike.%$trimmed%,name.ilike.%$trimmed%');
      }
      final rows =
          await builder.order('created_at', ascending: false) as List<dynamic>;
      return rows.cast<Map<String, dynamic>>().map(AppUser.fromJson).toList();
    } on PostgrestException catch (error) {
      AppLogger.error('User list failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<AppUser> getById(String id) async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row == null) {
        throw const AppException('User not found.');
      }
      return AppUser.fromJson(row);
    } on PostgrestException catch (error) {
      AppLogger.error('User load failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<AppUser> updateUser({
    required String id,
    String? name,
    String? role,
    bool? isActive,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name.trim();
      if (role != null) payload['role'] = role;
      if (isActive != null) payload['is_active'] = isActive;
      if (payload.isEmpty) {
        return getById(id);
      }
      final row = await _client
          .from('profiles')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      return AppUser.fromJson(row);
    } on PostgrestException catch (error) {
      AppLogger.error('User update failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }
}
