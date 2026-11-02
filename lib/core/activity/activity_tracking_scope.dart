import 'package:flutter/widgets.dart';

import 'activity_tracker.dart';

/// Accessible across feature modules without modifying BLoC dependencies.
class ActivityTrackingScope extends InheritedWidget {
  const ActivityTrackingScope({
    super.key,
    required this.tracker,
    required super.child,
  });

  final ActivityTracker? tracker;

  static ActivityTracker? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ActivityTrackingScope>()
          ?.tracker;

  @override
  bool updateShouldNotify(ActivityTrackingScope oldWidget) =>
      !identical(tracker, oldWidget.tracker);
}

class ActivityLifecycleObserver extends StatefulWidget {
  const ActivityLifecycleObserver({
    super.key,
    required this.tracker,
    required this.child,
  });

  final ActivityTracker? tracker;
  final Widget child;

  @override
  State<ActivityLifecycleObserver> createState() =>
      _ActivityLifecycleObserverState();
}

class _ActivityLifecycleObserverState extends State<ActivityLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      widget.tracker?.onBackground();
    } else if (state == AppLifecycleState.resumed) {
      widget.tracker?.onForeground();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Observe only explicitly named routes; never send raw user-supplied paths.
class ActivityNavigationObserver extends NavigatorObserver {
  ActivityNavigationObserver(this.tracker);
  final ActivityTracker tracker;

  void _record(Route<dynamic>? route) {
    final path = route?.settings.name?.toLowerCase();
    if (path == null) return;
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    const names = <String, String>{
      'education': 'learning',
      'learning': 'learning',
      'trade-ideas': 'trade_ideas',
      'trade-journal': 'journal',
      'journal': 'journal',
      'economic-news': 'news',
      'news': 'news',
      'affiliate': 'affiliate',
      'support': 'support',
      'copy-trade': 'copy_trading',
      'funded-advisor': 'funded_accounts',
      'investment': 'investments',
      'investments': 'investments',
      'risk-reward': 'calculator',
      'profile': 'profile',
    };
    for (final part in parts) {
      final module = names[part];
      if (module != null) {
        tracker.view(module, '${module}_route');
        return;
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _record(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _record(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _record(newRoute);
  }
}
