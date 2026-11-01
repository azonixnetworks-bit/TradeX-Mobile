import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';
import '../data/trade_journal_models.dart';
import '../data/trade_journal_repository.dart';
import 'trade_journal_dashboard_widgets.dart';
import 'trade_journal_insights_screens.dart';
import 'trade_journal_trade_screens.dart';
import 'trade_journal_ui.dart';

part 'journal_sections/journal_home.dart';
part 'journal_sections/journal_entries.dart';
part 'journal_sections/journal_filters.dart';
part 'journal_sections/journal_details.dart';
