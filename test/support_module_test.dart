import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/core/auth/secure_session_store.dart';
import 'package:tradex_mobile/core/device/device_identity.dart';
import 'package:tradex_mobile/core/network/tradex_api_client.dart';
import 'package:tradex_mobile/core/theme/tradex_theme.dart';
import 'package:tradex_mobile/features/support/data/models/support_models.dart';
import 'package:tradex_mobile/features/support/domain/support_policy.dart';
import 'package:tradex_mobile/features/support/domain/usecases/support_use_cases.dart';
import 'package:tradex_mobile/features/support/presentation/support_module.dart';
import 'package:tradex_mobile/features/support/support_dependencies.dart';

void main() {
  late TradeXApiClient apiClient;
  late SupportUseCases useCases;

  setUp(() {
    final store = SecureSessionStore();
    apiClient = TradeXApiClient(store, DeviceIdentity(store));
    useCases = SupportDependencies(apiClient).useCases;
  });

  test('support live-chat models parse server counts and assignment', () {
    final overview = SupportOverviewModel.fromJson({
      'ticket_counts': {'open': 2, 'resolved': 4, 'closed': 1},
      'live_chat': {'agents_online': 3, 'available': true},
    }).toEntity();
    final session = SupportChatSessionModel.fromJson({
      'uuid': 'chat-uuid',
      'ticket_uuid': 'ticket-uuid',
      'ticket_reference': 'TX-SUP-000001',
      'state': 'assigned',
      'queue_position': null,
      'eta_minutes': null,
      'agents_online': 3,
      'assigned_agent': {'name': 'Support Agent'},
    }).toEntity();

    expect(overview.agentsOnline, 3);
    expect(overview.openTickets, 2);
    expect(session.isConnected, isTrue);
    expect(session.assignedAgentName, 'Support Agent');
  });

  for (final width in const [360.0, 390.0, 430.0]) {
    testWidgets('support home is responsive at ${width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: TradeXTheme.dark,
          home: SupportHomeScreen(useCases: useCases),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('How can we help you?'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.text('TradeX'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('all eight support screens render honest backend states', (
    tester,
  ) async {
    final screens = <(Widget, String)>[
      (SupportHomeScreen(useCases: useCases), 'How can we help you?'),
      (CreateSupportTicketScreen(useCases: useCases), 'Create Support Ticket'),
      (MySupportTicketsScreen(useCases: useCases), 'My Support Tickets'),
      (TicketDetailsScreen(useCases: useCases), 'Ticket Details'),
      (
        LiveChatWaitingScreen(useCases: useCases),
        'Finding the right support agent for you',
      ),
      (LiveChatConversationScreen(useCases: useCases), 'Live Support'),
      (HelpCenterScreen(useCases: useCases), 'Help Center'),
      (TicketFeedbackScreen(useCases: useCases), 'Ticket Resolved'),
    ];

    for (final screen in screens) {
      await tester.pumpWidget(
        MaterialApp(theme: TradeXTheme.dark, home: screen.$1),
      );
      await tester.pumpAndSettle();
      expect(find.text(screen.$2), findsOneWidget, reason: screen.$2);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(tester.takeException(), isNull, reason: screen.$2);
    }
  });

  testWidgets('support home routes to ticket and FAQ experiences', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: SupportHomeScreen(useCases: useCases),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Ticket'));
    await tester.pumpAndSettle();
    expect(find.text('Create Support Ticket'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Help Center & FAQ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Help Center & FAQ'));
    await tester.pumpAndSettle();
    expect(find.text('Help Center'), findsOneWidget);
  });

  testWidgets('feedback rating is interactive without fake submission', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TradeXTheme.dark,
        home: TicketFeedbackScreen(useCases: useCases),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('4 stars'));
    await tester.ensureVisible(find.text('Submit Feedback'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit Feedback'));
    await tester.pump();

    expect(find.text(SupportPolicy.unavailableMessage), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
