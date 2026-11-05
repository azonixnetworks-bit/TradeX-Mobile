# TradeX Flutter Phase 05.6 — Visual Replay Integration

Adds a **replay-backtesting** service entry to the existing TradeX Home Services + Catalog. The five existing Home tabs are unchanged. The new `ReplayTerminalScreen` uses Flutter BLoC/Cubit and the existing `webview_flutter` package. It hosts the LOCAL Phase 05.5 Vite build, not a public website or remote CDNs.

## Critical installation step

The Mobile repository contains a *deliberately unbuilt* `assets/replay_terminal/` placeholder. A functioning WebView chart requires **building the independent Replay Terminal** with Vite and exporting compiled assets into TradeX-Mobile. Until then, the app shows a clear 'Replay Terminal Unavailable' screen rather than a blank WebView.

In Windows PowerShell (replace the mobile path with your actual folder):

```powershell
cd G:\TradeX-Replay
# Pull Phase 05.6 changes in Replay repository
git pull origin main
cd .\apps\replay-terminal
npm install
npm test
npm run build
npm run export:flutter -- "G:\TradeX-Mobile"

cd G:\TradeX-Mobile
flutter pub get
flutter analyze
flutter test test\features\replay\replay_terminal_cubit_test.dart
flutter run
```

**Do not** use the previous uncompiled HTML/TypeScript source as the Flutter asset; the WebView only receives compiled Vite files and a local SHA-256 manifest. No secret API key is exported. After build/export, rebuild/reinstall the Flutter app so the asset bundle is packaged into the application.

## File map

- `lib/features/replay/presentation/replay_terminal_screen.dart`: route-local WebView; asset checks; system orientation restoration; pause on background; blocked external navigation; no trade submission.
- `lib/features/replay/presentation/bloc/replay_terminal_cubit.dart`: versioned JavaScriptChannel event validation; visual-only readiness gate; command ID generation and allowlist.
- `test/features/replay/replay_terminal_cubit_test.dart`: no-execution gate and protocol tests.
- `lib/features/catalog/models/feature_spec.dart`: `replay-backtesting` service.
- `lib/features/catalog/catalog_dependencies.dart`: dedicated ReplayTerminalScreen route.
- `lib/features/catalog/presentation/feature_catalog_screen.dart`: activity module `replay`.
- `pubspec.yaml`: `assets/replay_terminal/` folder.
- `assets/replay_terminal/bundle_manifest.json`: originally built=false, overwritten by export.

## Data and parity limitations

- Standalone chart uses **SYNTHETIC fixture candles**. It is not authorized Deriv market history.
- Flutter receives chart state/events and can send Play/Pause/Step commands. The JS clock remains the only UI replay clock; Flutter does not start a second timer.
- Buy/Sell are **draft/price-level previews only**. Commands for order execution are strictly prohibited from the host allowlist.
- Existing Python `TradeSimulator` has NOT been ported to or run inside the WebView. A Python ↔ client parity suite must cover execution/fill/pnl/gaps/checkpoints before any virtual execution controls are unlocked.
- Authenticated history delivery and user entitlements, MySQL sessions, licensed data distribution and production scaling are not done in this milestone.
- Flutter SDK is unavailable in the authoring environment; actual `flutter analyze`, widget tests and device WebView smoke testing must be run locally or in CI. Do not claim a working Android/iOS release until those pass.
