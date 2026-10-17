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
}
