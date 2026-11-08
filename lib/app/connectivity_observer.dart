import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/network/tradex_api_client.dart';
import 'bloc/connectivity_cubit.dart';

/// Keeps the global connectivity banner out of the login design only.
/// Connectivity detection and the banner on every other screen are unchanged.
class ConnectivityBannerVisibility extends InheritedWidget {
  const ConnectivityBannerVisibility({
    super.key,
    required this.hidden,
    required super.child,
  });

  final ValueNotifier<bool> hidden;

  static ValueNotifier<bool>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ConnectivityBannerVisibility>()
        ?.hidden;
  }

  @override
  bool updateShouldNotify(ConnectivityBannerVisibility oldWidget) =>
      hidden != oldWidget.hidden;
}

class ConnectivityObserver extends StatefulWidget {
  const ConnectivityObserver({
    super.key,
    required this.child,
    required this.apiClient,
  });

  final Widget child;
  final TradeXApiClient apiClient;

  @override
  State<ConnectivityObserver> createState() => _ConnectivityObserverState();
}

class _ConnectivityObserverState extends State<ConnectivityObserver> {
  final ValueNotifier<bool> _hideBannerOnLogin = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hideBannerOnLogin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ConnectivityCubit(widget.apiClient)..start(),
    child: ValueListenableBuilder<bool>(
      valueListenable: _hideBannerOnLogin,
      child: ConnectivityBannerVisibility(
        hidden: _hideBannerOnLogin,
        child: widget.child,
      ),
      builder: (context, hideBanner, child) =>
          BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
        builder: (context, status) => Stack(
          children: [
            child!,
            if (status == ConnectivityStatus.offline && !hideBanner)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: ColoredBox(
                    color: const Color(0xFFE2A72E),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              IconData(0xe37c, fontFamily: 'MaterialIcons'),
                              size: 16,
                              color: Color(0xFF101612),
                            ),
                            SizedBox(width: 7),
                            Text(
                              "You're offline — showing saved data",
                              style: TextStyle(
                                color: Color(0xFF101612),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
