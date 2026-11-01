import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/trade_journal_models.dart';
import '../data/trade_journal_repository.dart';
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
