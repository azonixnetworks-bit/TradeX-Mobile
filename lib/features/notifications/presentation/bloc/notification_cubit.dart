import 'package:bloc/bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/notification_repository.dart';
import '../../domain/notification_models.dart';

enum NotificationLoadStatus { initial, loading, ready, failure }

class NotificationState {
  const NotificationState({
    this.status = NotificationLoadStatus.initial,
    this.filter = NotificationFeedFilter.all,
    this.items = const [],
    this.unreadCount = 0,
    this.total = 0,
    this.working = false,
    this.error,
  });

  final NotificationLoadStatus status;
  final NotificationFeedFilter filter;
  final List<TradeXNotification> items;
  final int unreadCount;
  final int total;
  final bool working;
  final String? error;

  NotificationState copyWith({
    NotificationLoadStatus? status,
    NotificationFeedFilter? filter,
    List<TradeXNotification>? items,
    int? unreadCount,
    int? total,
    bool? working,
    String? error,
    bool clearError = false,
  }) => NotificationState(
    status: status ?? this.status,
    filter: filter ?? this.filter,
    items: items ?? this.items,
    unreadCount: unreadCount ?? this.unreadCount,
    total: total ?? this.total,
    working: working ?? this.working,
    error: clearError ? null : error ?? this.error,
  );
}

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit(this.repository) : super(const NotificationState());

  final NotificationDataSource repository;

  Future<void> initialize() => _load(state.filter);

  Future<void> refresh() => _load(state.filter, keepContent: true);

  Future<void> selectFilter(NotificationFeedFilter filter) async {
    if (state.filter == filter &&
        state.status == NotificationLoadStatus.ready) {
      return;
    }
    emit(state.copyWith(filter: filter));
    await _load(filter);
  }

  Future<void> markAllRead() async {
    if (state.working || state.unreadCount == 0) return;
    emit(state.copyWith(working: true, clearError: true));
    try {
      final unread = await repository.markAllRead();
      emit(
        state.copyWith(
          working: false,
          unreadCount: unread,
          items: state.filter == NotificationFeedFilter.unread
              ? const []
              : state.items
                    .map((item) => item.copyWith(isRead: true))
                    .toList(growable: false),
        ),
      );
    } catch (error) {
      emit(state.copyWith(working: false, error: _message(error)));
    }
  }

  Future<void> markRead(String uuid) async {
    final index = state.items.indexWhere((item) => item.uuid == uuid);
    if (index < 0 || state.items[index].isRead) return;
    try {
      final unread = await repository.markRead(uuid);
      final updated = [...state.items];
      if (state.filter == NotificationFeedFilter.unread) {
        updated.removeAt(index);
      } else {
        updated[index] = updated[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }
      emit(state.copyWith(items: updated, unreadCount: unread));
    } catch (error) {
      emit(state.copyWith(error: _message(error)));
    }
  }

  Future<void> _load(
    NotificationFeedFilter filter, {
    bool keepContent = false,
  }) async {
    emit(
      state.copyWith(
        status: NotificationLoadStatus.loading,
        items: keepContent ? state.items : const [],
        clearError: true,
      ),
    );
    try {
      final feed = await repository.feed(filter);
      if (state.filter != filter) return;
      emit(
        state.copyWith(
          status: NotificationLoadStatus.ready,
          items: feed.items,
          unreadCount: feed.unreadCount,
          total: feed.total,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: NotificationLoadStatus.failure,
          error: _message(error),
        ),
      );
    }
  }

  String _message(Object error) => error is ApiException
      ? error.message
      : 'Notifications are temporarily unavailable. Please try again.';
}
