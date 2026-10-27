import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/features/trade_ideas/models/trade_idea_models.dart';

void main() {
  test('summary parses aggregate targets without expecting target rows', () {
    final summary = TradeIdeaSummary.fromJson({
      'uuid': '123e4567-e89b-42d3-a456-426614174000',
      'symbol': 'XAUUSD',
      'category': 'FOREX',
      'targets': {'total': 3, 'hit': 1},
      'entry': {'low': '2416.00', 'high': '2420.00'},
      'stop_loss': {'current': '2406.00'},
      'reactions': {'likes_count': 4},
    });

    expect(summary.targetsTotal, 3);
    expect(summary.targetsHit, 1);
    expect(summary.entry.display, '2416.00 – 2420.00');
  });

  test('detail converts target rows into accurate aggregate counts', () {
    final detail = TradeIdeaDetail.fromJson({
      'uuid': '123e4567-e89b-42d3-a456-426614174000',
      'symbol': 'BTCUSDT',
      'category': 'CRYPTO',
      'targets': [
        {'label': 'TP1', 'price': '70000', 'is_hit': true},
        {'label': 'TP2', 'price': '71000', 'is_hit': false},
      ],
    });

    expect(detail.targets, hasLength(2));
    expect(detail.summary.targetsTotal, 2);
    expect(detail.summary.targetsHit, 1);
  });
}
