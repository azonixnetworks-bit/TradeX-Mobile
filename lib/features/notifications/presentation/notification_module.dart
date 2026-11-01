import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/tradex_colors.dart';
import '../data/notification_repository.dart';
import '../domain/notification_models.dart';
import '../platform/notification_permission_service.dart';
import 'bloc/notification_cubit.dart';

part 'screens/notification_center_screen.dart';
part 'screens/notification_detail_screen.dart';
part 'screens/notification_preferences_screen.dart';
part 'screens/push_notification_screen.dart';
part 'widgets/notification_module_widgets.dart';

typedef NotificationActionCallback = FutureOr<void> Function(
  TradeXNotification notification,
);
