import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocAsyncState<T> {
  const BlocAsyncState({required this.connectionState, this.data, this.error});

  const BlocAsyncState.waiting()
    : connectionState = ConnectionState.waiting,
      data = null,
      error = null;

  final ConnectionState connectionState;
  final T? data;
  final Object? error;

  bool get hasError => error != null;
  bool get hasData => data != null;
  T get requireData => data as T;
}

class BlocFutureCubit<T> extends Cubit<BlocAsyncState<T>> {
  BlocFutureCubit() : super(const BlocAsyncState.waiting());

  int _requestId = 0;

  Future<void> load(Future<T>? future) async {
    final requestId = ++_requestId;
    if (future == null) {
      emit(BlocAsyncState<T>(connectionState: ConnectionState.none));
      return;
    }
    emit(const BlocAsyncState.waiting());
    try {
      final data = await future;
      if (!isClosed && requestId == _requestId) {
        emit(
          BlocAsyncState<T>(connectionState: ConnectionState.done, data: data),
        );
      }
    } catch (error) {
      if (!isClosed && requestId == _requestId) {
        emit(
          BlocAsyncState<T>(
            connectionState: ConnectionState.done,
            error: error,
          ),
        );
      }
    }
  }
}

class BlocFutureBuilder<T> extends StatefulWidget {
  const BlocFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
  });

  final Future<T>? future;
  final Widget Function(BuildContext context, BlocAsyncState<T> state) builder;

  @override
  State<BlocFutureBuilder<T>> createState() => _BlocFutureBuilderState<T>();
}

class _BlocFutureBuilderState<T> extends State<BlocFutureBuilder<T>> {
  late final BlocFutureCubit<T> _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = BlocFutureCubit<T>()..load(widget.future);
  }

  @override
  void didUpdateWidget(covariant BlocFutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.future, widget.future)) {
      _cubit.load(widget.future);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: BlocBuilder<BlocFutureCubit<T>, BlocAsyncState<T>>(
      builder: widget.builder,
    ),
  );
}
