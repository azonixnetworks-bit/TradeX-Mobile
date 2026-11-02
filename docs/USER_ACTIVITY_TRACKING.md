# TradeX Flutter — Activity tracking (feature branch)

## Scope and rollout

- This is additive telemetry; it does not replace the existing server-side security audit log.
- Disabled by default with compile-time flag TRADEX_ACTIVITY_TRACKING_ENABLED.
- Enable ONLY after Laravel PR #98 is deployed, migrated and tested (including its journal_saved event allowlist update).
- Enable via: flutter run --dart-define=TRADEX_ACTIVITY_TRACKING_ENABLED=true
- Backend contract: POST /api/v1/activity/events (Sanctum authenticated).
- Offline retry uses an encrypted, account-scoped outbox with a maximum of 300 events and 6-day local retention.
- Event batches have at most 25 items; event_id is a UUID for idempotent server ingestion.
- Periodic batch upload every 2 minutes, on session activation, and on app resume.
- Explicit logout purges the pending outbox for the signed-out account.

## Instrumentation

- Successful sign-in, unlock and restored authenticated session activate tracking.
- Flutter app background/foreground transitions produce session pause/resume events; session end is best effort.
- Dashboard Home, Learn, Trade Ideas, Affiliate, Profile tab visits.
- Feature catalogue opens and named navigation category visits.
- Lessons viewed by UUID and lessons marked complete after updateProgress was accepted; the existing API may queue progress offline, so completion is client-reported until confirmed server-side.
- Trade idea details viewed by UUID.
- Journal screen opened; journal save after successful API create/update response.
- Risk/reward calculations tracked only when a non-null calculator result is returned (Forex/Deriv, Crypto, Stocks, Dividend).

## Important safety rules

- The server determines user_id from the authenticated token. Client-reported payment/admin/security actions are not accepted.
- Only allowlisted module/event values and safe identifiers; no journal notes, chat text, emails, prices or secrets.
- Signal/lesson views mean opened screens, NOT proof of trading or reading.
- Failed telemetry must never stop login, navigation, payments, or other business logic.
- HTTP 403/404 disables upload for this app process; 400/422 invalid batches are dropped; temporary failures retry.
- Session duration is an estimate: OS process termination can prevent an end event.
- Publish appropriate privacy notice and retention policy before enabling.

## Local verification before merge

dart format lib/core/activity lib/main.dart lib/app/tradex_app.dart lib/features/auth/presentation/session_gate.dart lib/features/home/presentation/home_dashboard_screen.dart lib/features/catalog/presentation/feature_catalog_screen.dart lib/features/learn/presentation/learn_module.dart lib/features/trade_ideas/presentation/trade_idea_details_screen.dart lib/features/journal/presentation/trade_journal_trade_screens.dart test/activity_tracker_test.dart
flutter analyze
flutter test test/activity_tracker_test.dart
flutter test

Main remains untouched; tests not executed in this environment (Flutter/Dart SDK unavailable).
