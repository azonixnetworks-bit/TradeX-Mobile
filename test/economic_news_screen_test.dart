import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/home/presentation/economic_news_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('economic news shows requested columns and impact filters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = SecureSessionStore();
    final api = _NewsApiClient(store, DeviceIdentity(store));

    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: EconomicNewsScreen(apiClient: api),
      ),
    );
    await tester.pumpAndSettle();

    for (final filter in const ['Overview', 'High Impact', 'Medium Impact']) {
      expect(find.text(filter), findsOneWidget);
    }
    for (final heading in const [
      'Event / Source',
      'Remaining Time',
      'Impact',
      'Bias',
      'Confidence',
      'Affected Pairs',
    ]) {
      expect(find.text(heading), findsOneWidget);
    }
    expect(find.text('US CPI'), findsOneWidget);
    expect(find.text('ECB Rate Decision'), findsOneWidget);
    expect(find.text('Japan Consumer Confidence'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('economic-news-filter-high')));
    await tester.pumpAndSettle();

    expect(find.text('US CPI'), findsOneWidget);
    expect(find.text('ECB Rate Decision'), findsNothing);
    expect(find.text('Japan Consumer Confidence'), findsNothing);
    await tester.drag(
      find.byKey(const ValueKey('economic-news-filters')),
      const Offset(-240, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Low Impact'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _NewsApiClient extends TradeXApiClient {
  _NewsApiClient(super.sessionStore, super.deviceIdentity);

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    return <String, dynamic>{
      'data': <String, dynamic>{
        'events': <Map<String, dynamic>>[
          _event('high', 'US CPI', 'HIGH', 'BEARISH', 82, 'EURUSD'),
          _event(
            'medium',
            'ECB Rate Decision',
            'MEDIUM',
            'NEUTRAL',
            64,
            'EURGBP',
          ),
          _event(
            'low',
            'Japan Consumer Confidence',
            'LOW',
            'BULLISH',
            48,
            'USDJPY',
          ),
        ],
      },
    };
  }

  Map<String, dynamic> _event(
    String id,
    String title,
    String impact,
    String bias,
    int confidence,
    String pair,
  ) => <String, dynamic>{
    'uuid': id,
    'title': title,
    'impact': impact,
    'bias': bias,
    'confidence_score': confidence,
    'status': 'SCHEDULED',
    'scheduled_at_utc': DateTime.now()
        .toUtc()
        .add(const Duration(hours: 6))
        .toIso8601String(),
    'source': <String, dynamic>{'name': 'Trading Economics'},
    'affected_pairs': <Map<String, dynamic>>[
      <String, dynamic>{'symbol': pair},
    ],
  };
}
