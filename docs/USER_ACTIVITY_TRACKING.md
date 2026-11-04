# TradeX Flutter — Phase 1 user activity rollout

## Server-controlled activation

The client is now **ready to track by default**, but it must first call the authenticated/device-bound `GET /api/v1/activity/config`. No session or behavior events are stored before the Laravel server responds with `data.enabled=true` and `policy_version=1`.

The Laravel side is **disabled by default** using `TRADEX_ACTIVITY_ENABLED=false`. Do not enable until its schema/API and privacy disclosures are ready. A kill-switch build is available through `--dart-define=TRADEX_ACTIVITY_TRACKING_ENABLED=false`.

The network handshake and batched activity upload do not show connectivity banners, do not refresh sessions solely for analytics, do not cache endpoints, and do not enqueue mutations through TradeX's business-data offline queue. If the access token expires, telemetry retries only after normal app flows refresh the session.

## Phase 2 heartbeat and reporting

- While the app is foregrounded and the backend readiness flag is true, a session_heartbeat event is added every two minutes. No heartbeat is emitted while backgrounded or before server authorization.
- The Laravel Super Admin analytics dashboard uses heartbeat plus pause/resume events to estimate foreground minutes, capped at three minutes per event interval. These are not exact OS screen-time measurements.
- Phase 2 is stacked on the Phase 1 feature branch; merge Phase 1 first, then Phase 2, with a staged migration and real-device smoke test.

## Data captured

- Authenticated session started/paused/resumed/ended (best effort; app force-stop may omit end).
- Dashboard tab and feature entry, lesson viewed/completion interaction, trade-idea detail viewed, journal viewed/saved, and successful calculator use.
- Events use allowlisted categories/IDs only: no passwords, TOTP, email, journal notes, trade financial figures, or chat content.
- Events are not evidence of a real trade, completed learning, financial approval, or successful security operation.

## Delivery and safety

- Account-bound encrypted local outbox (existing `flutter_secure_storage`), maximum 300 records and up to 6 days pending.
- Up to 25 events per API batch with UUID idempotency on Laravel.
- Silent retries every 2 minutes, on session resumption and app activation.
- Backend disabled/unsupported response suspends and clears queued telemetry; readiness is retried later.
- The API checks the **current session user UUID** before every batch to prevent cross-account event attribution.
- Logout clears pending activity for that account. Telemetry never prevents logout.
- User can disable local collection entirely at build time; business features and BLoC flows are unchanged.

## Verification

The GitHub activity-phase1 CI workflow runs `flutter analyze` on the modified components and `flutter test test/activity_tracker_test.dart`. Test on a real staging device as well: app login/unlock, foreground/background, online/offline transitions, logout/account switch and server kill switch. Confirm events arrive in Laravel's `user_activity_events` and the Super Admin customer activity panel.

For rollout order, staging smoke tests, scheduler and rollback commands, see the Laravel repository's `docs/USER_ACTIVITY_PHASE1_ROLLOUT.md`. GitHub merge alone does not establish production activation.
