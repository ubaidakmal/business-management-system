class MarketRate {
  const MarketRate({
    required this.symbol,
    required this.baseCurrency,
    required this.currency,
    required this.value,
    required this.source,
    required this.fetchedAt,
    this.id,
  });

  final String? id;
  final String symbol;
  final String baseCurrency;
  final String currency;
  final double value;
  final String source;
  final DateTime fetchedAt;

  factory MarketRate.fromJson(Map<String, dynamic> json) {
    return MarketRate(
      id: json['id'] as String?,
      symbol: json['symbol'] as String? ?? '',
      baseCurrency: json['base_currency'] as String? ?? '',
      currency: json['currency'] as String? ?? '',
      value: _toDouble(json['value']),
      source: json['source'] as String? ?? '',
      fetchedAt: _parseDate(json['fetched_at']) ?? DateTime.now(),
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

class MarketRefreshResult {
  const MarketRefreshResult({
    required this.base,
    required this.source,
    required this.provider,
    required this.fetchedAt,
    required this.rates,
  });

  final String base;
  final String source;
  final String provider;
  final DateTime fetchedAt;
  final List<MarketRate> rates;

  factory MarketRefreshResult.fromJson(Map<String, dynamic> json) {
    final ratesRaw = json['rates'];
    final rates = <MarketRate>[];
    if (ratesRaw is List) {
      for (final row in ratesRaw) {
        if (row is Map<String, dynamic>) {
          rates.add(MarketRate.fromJson(row));
        } else if (row is Map) {
          rates.add(MarketRate.fromJson(Map<String, dynamic>.from(row)));
        }
      }
    }
    return MarketRefreshResult(
      base: json['base'] as String? ?? '',
      source: json['source'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      fetchedAt: MarketRate._parseDate(json['fetched_at']) ?? DateTime.now(),
      rates: rates,
    );
  }
}

class MarketHistoryPoint {
  const MarketHistoryPoint({required this.fetchedAt, required this.value});

  final DateTime fetchedAt;
  final double value;
}
