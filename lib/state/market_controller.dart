import 'package:flutter/foundation.dart';

import '../core/utils/app_error.dart';
import '../models/market_data.dart';
import '../services/market_service.dart';
import '../services/settings_service.dart';
import 'app_status.dart';

class MarketController extends ChangeNotifier {
  MarketController({
    MarketService? marketService,
    SettingsService? settingsService,
  }) : _market = marketService ?? MarketService(),
       _settings = settingsService ?? SettingsService();

  final MarketService _market;
  final SettingsService _settings;

  AppStatus status = AppStatus.initial;
  AppStatus refreshStatus = AppStatus.initial;
  List<MarketRate> rates = const [];
  List<MarketRate> history = const [];
  String? selectedSymbol;
  String? errorMessage;
  String? refreshError;
  DateTime? lastUpdated;
  String? source;
  bool marketEnabled = true;
  String baseCurrency = 'USD';

  bool get isLoading => status.isLoading;
  bool get isRefreshing => refreshStatus.isLoading;

  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final settings = await _settings.load();
      marketEnabled = settings.marketEnabled;
      baseCurrency = settings.marketBaseCurrency;
      if (!marketEnabled) {
        rates = const [];
        status = AppStatus.empty;
        errorMessage = 'Market data is disabled in settings.';
        notifyListeners();
        return;
      }

      rates = await _market.listLatest(baseCurrency: baseCurrency);
      if (rates.isNotEmpty) {
        lastUpdated = rates
            .map((r) => r.fetchedAt)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        source = rates.first.source;
        selectedSymbol ??= rates.first.symbol;
        await _loadHistory(selectedSymbol!);
      } else {
        history = const [];
      }
      status = rates.isEmpty ? AppStatus.empty : AppStatus.success;
    } catch (error) {
      status = AppStatus.error;
      errorMessage = AppError.messageOf(error);
    }
    notifyListeners();
  }

  Future<void> selectSymbol(String symbol) async {
    selectedSymbol = symbol;
    await _loadHistory(symbol);
    notifyListeners();
  }

  Future<void> _loadHistory(String symbol) async {
    try {
      history = await _market.listHistory(symbol: symbol);
    } catch (_) {
      history = const [];
    }
  }

  Future<bool> refresh() async {
    refreshStatus = AppStatus.loading;
    refreshError = null;
    notifyListeners();
    try {
      final settings = await _settings.load();
      if (!settings.marketEnabled) {
        refreshStatus = AppStatus.error;
        refreshError = 'Market data is disabled in settings.';
        notifyListeners();
        return false;
      }
      final quotes = settings.marketQuoteCurrencies
          .split(',')
          .map((s) => s.trim().toUpperCase())
          .where((s) => s.length == 3)
          .toList();
      final result = await _market.refresh(
        base: settings.marketBaseCurrency,
        quotes: quotes,
      );
      source = result.source;
      lastUpdated = result.fetchedAt;
      baseCurrency = settings.marketBaseCurrency;
      marketEnabled = settings.marketEnabled;
      rates = await _market.listLatest(baseCurrency: baseCurrency);
      if (rates.isNotEmpty) {
        selectedSymbol ??= rates.first.symbol;
        if (selectedSymbol != null) {
          await _loadHistory(selectedSymbol!);
        }
        status = AppStatus.success;
      } else {
        history = const [];
        status = AppStatus.empty;
      }
      refreshStatus = AppStatus.success;
      notifyListeners();
      return true;
    } catch (error) {
      refreshStatus = AppStatus.error;
      refreshError = AppError.messageOf(error);
      notifyListeners();
      return false;
    }
  }

  List<MarketHistoryPoint> get historyPoints {
    return [
      for (final row in history)
        MarketHistoryPoint(fetchedAt: row.fetchedAt, value: row.value),
    ];
  }
}
