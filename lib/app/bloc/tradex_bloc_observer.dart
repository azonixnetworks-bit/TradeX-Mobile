import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

class TradeXBlocObserver extends BlocObserver {
  const TradeXBlocObserver();

  @override
  void onError(BlocBase<Object?> bloc, Object error, StackTrace stackTrace) {
    debugPrint('${bloc.runtimeType}: $error');
    super.onError(bloc, error, stackTrace);
  }
}
