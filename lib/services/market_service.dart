import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_error.dart';
import '../core/utils/app_logger.dart';
import '../models/market_data.dart';
import 'supabase_service.dart';

class MarketService {
  SupabaseClient get _client => SupabaseService.client;

  /// Latest row per symbol (most recent fetched_at).
  Future<List<MarketRate>> listLatest({String? baseCurrency}) async {
    try {
      var query = _client.from('market_data').select().eq('data_type', 'fx_rate');

      if (baseCurrency != null && baseCurrency.isNotEmpty) {
        query = query.eq('base_currency', baseCurrency.toUpperCase());
      }

      final rows =
          await query.order('fetched_at', ascending: false).limit(200)
              as List<dynamic>;
      final latestBySymbol = <String, MarketRate>{};
      for (final row in rows.cast<Map<String, dynamic>>()) {
        final rate = MarketRate.fromJson(row);
        latestBySymbol.putIfAbsent(rate.symbol, () => rate);
      }
      final list = latestBySymbol.values.toList()
        ..sort((a, b) => a.symbol.compareTo(b.symbol));
      return list;
    } on PostgrestException catch (error) {
      AppLogger.error('Market list failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  Future<List<MarketRate>> listHistory({
    required String symbol,
    int limit = 30,
  }) async {
    try {
      final rows =
          await _client
                  .from('market_data')
                  .select()
                  .eq('symbol', symbol)
                  .order('fetched_at', ascending: false)
                  .limit(limit)
              as List<dynamic>;
      return rows
          .cast<Map<String, dynamic>>()
          .map(MarketRate.fromJson)
          .toList()
          .reversed
          .toList();
    } on PostgrestException catch (error) {
      AppLogger.error('Market history failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }

  /// Calls Edge Function — external API keys stay server-side.
  Future<MarketRefreshResult> refresh({
    String? base,
    List<String>? quotes,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'fetch-market-rates',
        body: {
          if (base != null && base.isNotEmpty) 'base': base,
          if (quotes != null && quotes.isNotEmpty) 'quotes': quotes,
        },
      );

      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw AppException(data['error'].toString());
      }
      if (data is Map<String, dynamic>) {
        return MarketRefreshResult.fromJson(data);
      }
      if (data is Map) {
        return MarketRefreshResult.fromJson(Map<String, dynamic>.from(data));
      }
      throw const AppException('Unexpected market refresh response.');
    } on FunctionException catch (error) {
      AppLogger.error('Market refresh failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    } on PostgrestException catch (error) {
      AppLogger.error('Market refresh failed', error);
      throw AppException(AppError.messageOf(error), cause: error);
    }
  }
}
