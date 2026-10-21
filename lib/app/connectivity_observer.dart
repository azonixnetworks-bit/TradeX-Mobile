import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/network/tradex_api_client.dart';
import 'bloc/connectivity_cubit.dart';

class ConnectivityObserver extends StatelessWidget {
  const ConnectivityObserver({
    super.key,
    required this.child,
    required this.apiClient,
  });

  final Widget child;
  final TradeXApiClient apiClient;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ConnectivityCubit(apiClient)..start(),
    child: BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
      builder: (context, status) => Stack(
        children: [
          child,
          if (status == ConnectivityStatus.offline)
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
  );
}
