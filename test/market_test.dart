import 'package:flutter_test/flutter_test.dart';

import 'package:business_management_app/models/app_settings.dart';
import 'package:business_management_app/models/market_data.dart';
import 'package:business_management_app/models/permission.dart';

void main() {
  test('MarketRate.fromJson maps FX fields', () {
    final rate = MarketRate.fromJson({
      'id': 'm1',
      'symbol': 'USD/PKR',
      'base_currency': 'USD',
      'currency': 'PKR',
      'value': '278.50',
      'source': 'frankfurter.app',
      'fetched_at': '2026-09-11T10:00:00Z',
    });

    expect(rate.symbol, 'USD/PKR');
    expect(rate.value, 278.5);
    expect(rate.source, 'frankfurter.app');
  });

  test('MarketRefreshResult.fromJson maps rates list', () {
    final result = MarketRefreshResult.fromJson({
      'base': 'USD',
      'source': 'frankfurter.app',
      'provider': 'frankfurter',
      'fetched_at': '2026-09-11T10:00:00Z',
      'rates': [
        {
          'symbol': 'USD/EUR',
          'base_currency': 'USD',
          'currency': 'EUR',
          'value': 0.92,
          'source': 'frankfurter.app',
          'fetched_at': '2026-09-11T10:00:00Z',
        },
      ],
    });

    expect(result.rates, hasLength(1));
    expect(result.rates.single.currency, 'EUR');
  });

  test('AppSettings includes market fields', () {
    final settings = AppSettings.fromJson({
      'business_name': 'Acme',
      'market_enabled': false,
      'market_base_currency': 'eur',
      'market_quote_currencies': 'pkr,usd',
    });

    expect(settings.marketEnabled, isFalse);
    expect(settings.marketBaseCurrency, 'EUR');
    expect(settings.toUpdateJson()['market_quote_currencies'], 'PKR,USD');
  });

  test('AppPermissions includes market capabilities', () {
    final user = AppPermissions('user');
    final admin = AppPermissions('admin');
    expect(user.viewMarket, isTrue);
    expect(user.manageMarketSettings, isFalse);
    expect(admin.manageMarketSettings, isTrue);
    expect(user.grantedLabels, contains('View market data'));
  });
}
