import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_error.dart';
import '../core/utils/app_logger.dart';
import '../models/purchase.dart';
import 'supabase_service.dart';

class PurchaseService {
  SupabaseClient get _client => SupabaseService.client;

  static const _listSelect =
      '*, companies:company_id ( name ), purchase_items(count)';

  static const _detailSelect =
      '*, companies:company_id ( name ), purchase_items ( *, products:product_id ( name, sku, unit ) )';

  Future<List<Purchase>> list({
    String query = '',
    String? companyId,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      var builder = _client.from('purchases').select(_listSelect);

      if (companyId != null && companyId.isNotEmpty) {
        builder = builder.eq('company_id', companyId);
      }
      if (status != null && status.isNotEmpty) {
        builder = builder.eq('status', status);
      }
      if (dateFrom != null) {
        builder = builder.gte('purchase_date', _dateOnly(dateFrom));
      }
      if (dateTo != null) {
        builder = builder.lte('purchase_date', _dateOnly(dateTo));
      }

      final trimmed = query.trim();
      if (trimmed.isNotEmpty) {
        final companyRows =
            await _client
                    .from('companies')
                    .select('id')
                    .ilike('name', '%$trimmed%')
                as List<dynamic>;
        final companyIds = companyRows
            .cast<Map<String, dynamic>>()
            .map((row) => row['id'] as String)
            .toList();

        if (companyIds.isEmpty) {
          builder = builder.or(
            'invoice_number.ilike.%$trimmed%,reference_number.ilike.%$trimmed%',
          );
        } else {
          final idList = companyIds.join(',');
          builder = builder.or(
            'invoice_number.ilike.%$trimmed%,reference_number.ilike.%$trimmed%,company_id.in.($idList)',
          );
        }
      }

      final rows =
          await builder
                  .order('purchase_date', ascending: false)
                  .order('created_at', ascending: false)
              as List<dynamic>;
      return rows.cast<Map<String, dynamic>>().map(Purchase.fromJson).toList();
    } on PostgrestException catch (error) {
      AppLogger.error('Purchase list failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<Purchase> getById(String id) async {
    try {
      final row = await _client
          .from('purchases')
          .select(_detailSelect)
          .eq('id', id)
          .maybeSingle();
      if (row == null) {
        throw const AppException('Purchase not found.');
      }
      return Purchase.fromJson(row);
    } on PostgrestException catch (error) {
      AppLogger.error('Purchase load failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<String> create({
    required String companyId,
    required DateTime purchaseDate,
    String? invoiceNumber,
    String? referenceNumber,
    String? notes,
    required double discount,
    required double otherCharges,
    required String status,
    required List<PurchaseItem> items,
  }) async {
    try {
      final id = await _client.rpc(
        'create_purchase_with_items',
        params: {
          'p_company_id': companyId,
          'p_purchase_date': _dateOnly(purchaseDate),
          'p_invoice_number': _emptyToNull(invoiceNumber),
          'p_reference_number': _emptyToNull(referenceNumber),
          'p_notes': _emptyToNull(notes),
          'p_discount': discount,
          'p_other_charges': otherCharges,
          'p_status': status,
          'p_items': items.map((item) => item.toRpcJson()).toList(),
        },
      );
      return id as String;
    } on PostgrestException catch (error) {
      AppLogger.error('Purchase create failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    } on FunctionException catch (error) {
      AppLogger.error('Purchase create failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<String> updateDraft({
    required String purchaseId,
    required String companyId,
    required DateTime purchaseDate,
    String? invoiceNumber,
    String? referenceNumber,
    String? notes,
    required double discount,
    required double otherCharges,
    required String status,
    required List<PurchaseItem> items,
  }) async {
    try {
      final id = await _client.rpc(
        'update_draft_purchase_with_items',
        params: {
          'p_purchase_id': purchaseId,
          'p_company_id': companyId,
          'p_purchase_date': _dateOnly(purchaseDate),
          'p_invoice_number': _emptyToNull(invoiceNumber),
          'p_reference_number': _emptyToNull(referenceNumber),
          'p_notes': _emptyToNull(notes),
          'p_discount': discount,
          'p_other_charges': otherCharges,
          'p_status': status,
          'p_items': items.map((item) => item.toRpcJson()).toList(),
        },
      );
      return id as String;
    } on PostgrestException catch (error) {
      AppLogger.error('Purchase update failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    } on FunctionException catch (error) {
      AppLogger.error('Purchase update failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<void> cancel(String purchaseId) async {
    try {
      await _client.rpc(
        'cancel_purchase',
        params: {'p_purchase_id': purchaseId},
      );
    } on PostgrestException catch (error) {
      AppLogger.error('Purchase cancel failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    } on FunctionException catch (error) {
      AppLogger.error('Purchase cancel failed', error);
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

  String? _emptyToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
