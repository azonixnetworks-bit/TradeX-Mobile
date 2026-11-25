import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/features/catalog/models/feature_spec.dart';

void main() {
  test('investments are excluded from the current release catalog', () {
    expect(investmentsEnabled, isFalse);
    expect(
      tradeXFeatureSpecs.where((feature) => feature.id == 'investments'),
      isEmpty,
    );
  });
}
