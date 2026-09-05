import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_error.dart';
import '../core/utils/app_logger.dart';
import '../models/sale.dart';
import 'supabase_service.dart';

class SaleService {
  SupabaseClient get _client => SupabaseService.client;

  static const _listSelect =
      '*, companies:company_id ( name ), sale_items(count)';

  static const _detailSelect =
      '*, companies:company_id ( name ), sale_items ( *, products:product_id ( name, sku, unit ) )';

  Future<List<Sale>> list({
    String query = '',
    String? companyId,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      var builder = _client.from('sales').select(_listSelect);

      if (companyId != null && companyId.isNotEmpty) {
        builder = builder.eq('company_id', companyId);
      }
      if (status != null && status.isNotEmpty) {
        builder = builder.eq('status', status);
      }
      if (dateFrom != null) {
        builder = builder.gte('sale_date', _dateOnly(dateFrom));
      }
      if (dateTo != null) {
        builder = builder.lte('sale_date', _dateOnly(dateTo));
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
                  .order('sale_date', ascending: false)
                  .order('created_at', ascending: false)
              as List<dynamic>;
      return rows.cast<Map<String, dynamic>>().map(Sale.fromJson).toList();
    } on PostgrestException catch (error) {
      AppLogger.error('Sale list failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<Sale> getById(String id) async {
    try {
      final row = await _client
          .from('sales')
          .select(_detailSelect)
          .eq('id', id)
          .maybeSingle();
      if (row == null) {
        throw const AppException('Sale not found.');
      }
      return Sale.fromJson(row);
    } on PostgrestException catch (error) {
      AppLogger.error('Sale load failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<String> create({
    required String companyId,
    required DateTime saleDate,
    String? invoiceNumber,
    String? referenceNumber,
    String? notes,
    required double discount,
    required double otherCharges,
    required String status,
    required List<SaleItem> items,
  }) async {
    try {
      final id = await _client.rpc(
        'create_sale_with_items',
        params: {
          'p_company_id': companyId,
          'p_sale_date': _dateOnly(saleDate),
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
      AppLogger.error('Sale create failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    } on FunctionException catch (error) {
      AppLogger.error('Sale create failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<String> updateDraft({
    required String saleId,
    required String companyId,
    required DateTime saleDate,
    String? invoiceNumber,
    String? referenceNumber,
    String? notes,
    required double discount,
    required double otherCharges,
    required String status,
    required List<SaleItem> items,
  }) async {
    try {
      final id = await _client.rpc(
        'update_draft_sale_with_items',
        params: {
          'p_sale_id': saleId,
          'p_company_id': companyId,
          'p_sale_date': _dateOnly(saleDate),
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
      AppLogger.error('Sale update failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    } on FunctionException catch (error) {
      AppLogger.error('Sale update failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<void> cancel(String saleId) async {
    try {
      await _client.rpc('cancel_sale', params: {'p_sale_id': saleId});
    } on PostgrestException catch (error) {
      AppLogger.error('Sale cancel failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    } on FunctionException catch (error) {
      AppLogger.error('Sale cancel failed', error);
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
