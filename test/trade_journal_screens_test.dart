import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/journal/data/trade_journal_models.dart';
import 'package:tradex_mobile/features/journal/data/trade_journal_repository.dart';
import 'package:tradex_mobile/features/journal/presentation/trade_journal_home_screen.dart';
import 'package:tradex_mobile/features/journal/presentation/trade_journal_insights_screens.dart';
import 'package:tradex_mobile/features/journal/presentation/trade_journal_trade_screens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('all twelve trade journal screens render without bottom nav', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _JournalApiClient(store, DeviceIdentity(store));
    final repository = TradeJournalRepository(api, 'UTC');
    final entry = TradeJournalEntry.fromJson(_JournalApiClient.entry());
    final screens = <(Widget, String)>[
      (
        TradeJournalHomeScreen(apiClient: api, repository: repository),
        'Trade Journal',
      ),
      (TradeJournalEntriesScreen(repository: repository), 'All Trades'),
      (TradeJournalPlanScreen(repository: repository), 'Plan a Trade'),
      (
        TradeJournalDetailsScreen(repository: repository, entry: entry),
        'Trade Details',
      ),
      (
        TradeJournalPlanScreen(repository: repository, entry: entry),
        'Edit Planned Trade',
      ),
      (
        TradeJournalOpenScreen(repository: repository, entry: entry),
        'Open Trade',
      ),
      (
        TradeJournalCloseScreen(repository: repository, entry: entry),
        'Close Trade',
      ),
      (TradeJournalAnalyticsScreen(repository: repository), 'Trade Analytics'),
      (
        TradeJournalReviewScreen(repository: repository, type: 'weekly'),
        'Weekly Review',
      ),
      (
        TradeJournalReviewScreen(repository: repository, type: 'monthly'),
        'Monthly Review',
      ),
      (TradeJournalFiltersScreen(repository: repository), 'Search & Filters'),
      (
        TradeJournalScreenshotsScreen(repository: repository, entry: entry),
        'Trade Screenshots',
      ),
    ];

    for (final screen in screens) {
      await tester.pumpWidget(
        MaterialApp(theme: TradeXTheme.dark, home: screen.$1),
      );
      await tester.pumpAndSettle();
      expect(find.text(screen.$2), findsOneWidget, reason: screen.$2);
      expect(find.byType(BottomNavigationBar), findsNothing);
      final exception = tester.takeException();
      if (exception != null) throw exception;
    }
  });

  testWidgets('journal home opens the real all trades list', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _JournalApiClient(store, DeviceIdentity(store));
    final repository = TradeJournalRepository(api, 'UTC');

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: TradeJournalHomeScreen(apiClient: api, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Net P&L'), findsOneWidget);
    expect(find.text('Win Rate'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('All Trades'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('All Trades'));
    await tester.pumpAndSettle();
    expect(find.text('Search, filter and review your journal'), findsOneWidget);
    expect(find.text('BTCUSDT'), findsOneWidget);
    expect(
      api.paths.any((path) => path.startsWith('/api/v1/trade-journal?')),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('plan trade suggests market symbols and aligns trade choices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _JournalApiClient(store, DeviceIdentity(store));
    final repository = TradeJournalRepository(api, 'UTC');

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: TradeJournalPlanScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    final direction = tester.getTopLeft(
      find.byKey(const ValueKey('trade-direction-selector')),
    );
    final status = tester.getTopLeft(
      find.byKey(const ValueKey('trade-status-selector')),
    );
    expect(direction.dy, status.dy);

    await tester.enterText(
      find.byKey(const ValueKey('trade-symbol-field')),
      'btc',
    );
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('trade-symbol-suggestions')),
      findsOneWidget,
    );
    expect(find.text('BTCUSDT'), findsOneWidget);
    expect(find.text('Bitcoin / Tether'), findsOneWidget);
    expect(
      api.paths.any(
        (path) =>
            path.startsWith('/api/v1/screener/symbols?') &&
            path.contains('market=CRYPTO') &&
            path.contains('search=BTC'),
      ),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('trade-symbol-BTCUSDT')));
    await tester.pump();
    final symbolField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('trade-symbol-field')),
    );
    expect(symbolField.controller?.text, 'BTCUSDT');
    expect(
      find.byKey(const ValueKey('trade-symbol-suggestions')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

class _JournalApiClient extends TradeXApiClient {
  _JournalApiClient(super.sessionStore, super.deviceIdentity);

  final paths = <String>[];

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    paths.add(path);
    if (path.startsWith('/api/v1/trade-journal/meta')) {
      return {
        'data': {
          'markets': ['forex', 'crypto', 'deriv', 'stocks'],
          'stock_regions': ['sri_lanka_cse', 'india', 'international'],
          'directions': ['buy', 'sell'],
          'statuses': ['planned', 'open', 'closed', 'cancelled'],
          'results': ['win', 'loss', 'breakeven', 'partial'],
          'timeframes': ['M1', 'M5', 'M15', 'H1', 'H4', 'D1'],
          'emotions_before': ['calm', 'confident', 'fear'],
          'emotions_after': ['calm', 'satisfied', 'disappointed'],
          'followed_plan_after': ['yes', 'partially', 'no'],
          'mistake_tags': ['early_entry', 'fomo', 'overtrading'],
        },
      };
    }
    if (path.startsWith('/api/v1/screener/symbols?')) {
      return {
        'data': {
          'market': 'CRYPTO',
          'symbols': [
            {
              'symbol': 'BTCUSDT',
              'name': 'Bitcoin / Tether',
              'logo_url': 'https://example.test/btc.png',
            },
            {'symbol': 'BTTCUSDT', 'name': 'BitTorrent / Tether'},
          ],
        },
      };
    }
    if (path.startsWith('/api/v1/trade-journal/home')) {
      return {
        'data': {
          'timezone': 'Asia/Colombo',
          'today': summary(),
          'week': summary(),
          'month': summary(),
          'recent': [entry()],
        },
      };
    }
    if (path.startsWith('/api/v1/trade-journal/analytics')) {
      return {'data': analytics()};
    }
    if (path.startsWith('/api/v1/trade-journal/reviews/')) {
      return {
        'data': {
          'period_type': path.contains('monthly') ? 'monthly' : 'weekly',
          'period_start': '2026-10-19',
          'period_end': '2026-10-25',
          'timezone': 'Asia/Colombo',
          'summary': summary(),
          'review': null,
        },
      };
    }
    if (RegExp(r'^/api/v1/trade-journal/entry-1').hasMatch(path)) {
      return {'data': entry()};
    }
    if (path.startsWith('/api/v1/trade-journal?')) {
      return {
        'data': {
          'data': [entry()],
          'current_page': 1,
          'last_page': 1,
          'total': 1,
        },
      };
    }
    return const {'data': <String, dynamic>{}};
  }

  @override
  Future<Uint8List> getBytes(String path) async => Uint8List(0);

  static Map<String, dynamic> summary() => {
    'total_executed': 12,
    'open': 3,
    'closed': 9,
    'wins': 6,
    'losses': 3,
    'win_rate': 66.7,
    'net_pnl': 1284.5,
    'pnl_currency': 'USD',
    'plan_followed_percent': 83.3,
    'best_week': {'period': '2026-10-05', 'net_pnl': 900, 'currency': 'USD'},
    'worst_week': {'period': '2026-10-12', 'net_pnl': -120, 'currency': 'USD'},
  };

  static Map<String, dynamic> analytics() => {
    'overview': summary(),
    'risk': {'average_realized_r': 1.42},
    'performance': {
      'profit_factor': 2.35,
      'average_win': 320,
      'average_loss': -110,
      'max_win_streak': 4,
      'max_loss_streak': 2,
      'equity_curves': [
        {
          'currency': 'USD',
          'points': [
            {'cumulative_pnl': 200},
            {'cumulative_pnl': 80},
            {'cumulative_pnl': 1284.5},
          ],
        },
      ],
    },
    'sessions': [
      {'key': 'London', 'trades': 6, 'win_rate': 70},
    ],
    'symbols': [
      {'key': 'BTCUSDT', 'trades': 4, 'win_rate': 75},
    ],
    'discipline': {
      'plan_followed_percent': 83.3,
      'session_checked_percent': 90,
      'news_checked_percent': 80,
      'risk_checked_percent': 100,
      'most_common_mistake': 'early_entry',
    },
  };

  static Map<String, dynamic> entry() => {
    'uuid': 'entry-1',
    'market': 'crypto',
    'stock_region': null,
    'symbol': 'BTCUSDT',
    'direction': 'buy',
    'status': 'planned',
    'trade_at_local': '2026-10-23T10:00:00+05:30',
    'display_timezone': 'Asia/Colombo',
    'session': {
      'label': 'London / New York Overlap',
      'keys': ['london', 'new_york'],
      'source': 'auto',
    },
    'broker': 'Binance',
    'account_label': 'Main',
    'setup_strategy': 'Breakout',
    'timeframes': ['M15', 'H1'],
    'entry_reason': 'Breakout above resistance with volume.',
    'notes_before': 'Wait for candle close.',
    'prices': {
      'planned_entry': '68000',
      'actual_entry': null,
      'planned_sl': '66000',
      'current_sl': '66000',
      'planned_tp': '72000',
      'current_tp': '72000',
      'exit_price': null,
    },
    'risk': {
      'position_size': '0.1',
      'risk_amount': '200',
      'risk_currency': 'USD',
      'risk_percent': '1',
      'planned_rr': '2',
      'realized_r': null,
    },
    'psychology_before': {
      'emotion': 'calm',
      'confidence': 4,
      'note': 'Focused',
    },
    'checklist': {
      'followed_trading_plan': 'yes',
      'session_checked': 'yes',
      'news_checked': 'yes',
      'risk_checked': 'yes',
      'setup_confirmed': 'yes',
    },
    'execution_note': null,
    'opened_at': null,
    'exit_at': null,
    'result': null,
    'pnl': {
      'gross': null,
      'fees': null,
      'net': null,
      'currency': null,
      'percent': null,
    },
    'review': {'followed_plan': null, 'lesson_learned': null, 'rating': null},
    'screenshots': {'before_available': false, 'after_available': false},
    'actions': {
      'can_edit': true,
      'can_open': true,
      'can_close': false,
      'can_cancel': true,
    },
  };
}
