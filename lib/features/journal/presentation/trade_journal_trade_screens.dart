import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/activity/activity_tracking_scope.dart';
import '../../../core/domain/app_platform.dart';

import '../../../core/domain/user_facing_exception.dart';
import '../../../core/serialization/structured_text_codec.dart';
import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_design_system.dart';
import '../domain/entities/trade_journal_entities.dart';
import '../domain/repositories/trade_journal_repository.dart';
import 'trade_journal_close_sections.dart';
import 'trade_journal_risk_psychology_sections.dart';
import 'trade_journal_strategy_section.dart';
import 'trade_journal_ui.dart';

part 'trade_screens/trade_plan_screen.dart';
part 'trade_screens/trade_plan_screen_state.dart';
part 'trade_screens/trade_open_screen.dart';
part 'trade_screens/trade_close_screen.dart';
part 'trade_screens/trade_screenshots_screen.dart';
part 'trade_screens/trade_screen_shared_widgets.dart';

const _strategyReasonPrefix = 'TRADEX_STRATEGY_REASON_V1:';
