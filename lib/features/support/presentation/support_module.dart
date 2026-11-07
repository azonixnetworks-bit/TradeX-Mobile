import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/domain/app_platform.dart';

import 'package:uuid/uuid.dart';

import '../../../core/domain/user_facing_exception.dart';
import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_design_system.dart';
import '../domain/entities/support_entities.dart';
import '../domain/support_policy.dart';
import '../domain/usecases/support_use_cases.dart';

part 'screens/support_home_screen.dart';
part 'screens/support_help_screens.dart';
part 'screens/support_ticket_screens.dart';
part 'screens/support_live_chat_screens.dart';
part 'widgets/support_live_chat_widgets.dart';
part 'widgets/support_shared_widgets.dart';

const _iconRoot = 'assets/support/icons';
const _imageRoot = 'assets/support/images';
const _globeAsset =
    'assets/affiliate/illustrations/dashboard_network_globe.png';
