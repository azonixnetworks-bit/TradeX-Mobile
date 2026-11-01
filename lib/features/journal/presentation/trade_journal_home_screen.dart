import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/domain/user_facing_exception.dart';
import '../../../core/serialization/structured_text_codec.dart';
import '../../../core/theme/tradex_colors.dart';
import '../domain/entities/trade_journal_entities.dart';
import '../domain/repositories/trade_journal_repository.dart';
import 'trade_journal_dashboard_widgets.dart';
import 'trade_journal_insights_screens.dart';
import 'trade_journal_trade_screens.dart';
import 'trade_journal_ui.dart';

part 'journal_sections/journal_home.dart';
part 'journal_sections/journal_entries.dart';
part 'journal_sections/journal_filters.dart';
part 'journal_sections/journal_details.dart';
