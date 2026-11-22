import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/config/tradex_api_config.dart';

void main() {
  test('production API has at least one valid SHA-256 certificate pin', () {
    final pins = TradeXApiConfig.certificatePinsFor(
      TradeXApiConfig.productionHost,
    );

    expect(pins, isNotEmpty);
    expect(
      pins.every((pin) => RegExp(r'^[0-9a-f]{64}$').hasMatch(pin)),
      isTrue,
    );
  });

  test('custom development hosts do not inherit production pins', () {
    expect(TradeXApiConfig.certificatePinsFor('localhost'), isEmpty);
  });

  test('all production module hosts use certificate pins', () {
    for (final host in TradeXApiConfig.productionApiHosts) {
      expect(
        TradeXApiConfig.certificatePinsFor(host),
        isNotEmpty,
        reason: '$host must be certificate pinned',
      );
    }
  });

  test('module API paths resolve to isolated production hosts', () {
    expect(
      TradeXApiConfig.resolveRequestUrl('/api/v1/education/courses?page=1'),
      'https://education.tradex.lk/api/v1/education/courses?page=1',
    );
    expect(
      TradeXApiConfig.resolveRequestUrl('/api/v1/trade-ideas'),
      'https://signals.tradex.lk/api/v1/trade-ideas',
    );
    expect(
      TradeXApiConfig.resolveRequestUrl('/api/v1/affiliate/dashboard'),
      'https://affiliate.tradex.lk/api/v1/affiliate/dashboard',
    );
    expect(
      TradeXApiConfig.resolveRequestUrl('/api/v1/support/tickets'),
      'https://support.tradex.lk/api/v1/support/tickets',
    );
    expect(
      TradeXApiConfig.resolveRequestUrl('/api/v1/copy-trade/providers'),
      'https://copytrade.tradex.lk/api/v1/copy-trade/providers',
    );
    expect(
      TradeXApiConfig.resolveRequestUrl('/api/v1/screener/markets'),
      'https://screener.tradex.lk/api/v1/screener/markets',
    );
  });

  test('core API paths remain on the configured base URL', () {
    expect(
      TradeXApiConfig.resolveRequestUrl('/api/v1/auth/login'),
      '/api/v1/auth/login',
    );
  });
}
