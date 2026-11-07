import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_design_system.dart';
import '../domain/entities/notification_entities.dart';
import '../domain/repositories/notification_repository.dart';
import 'bloc/notification_cubit.dart';

part 'screens/notification_center_screen.dart';
part 'screens/notification_detail_screen.dart';
part 'screens/notification_preferences_screen.dart';
part 'screens/push_notification_screen.dart';
part 'widgets/notification_module_widgets.dart';

typedef NotificationActionCallback = FutureOr<void> Function(
  TradeXNotification notification,
);
