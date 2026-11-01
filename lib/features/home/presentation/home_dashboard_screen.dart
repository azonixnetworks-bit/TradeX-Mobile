import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/tradex_api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/bloc/bloc_future_builder.dart';
import '../../../core/platform/app_background_service.dart';
import '../../../core/profile/local_profile_photo_store.dart';
import '../../../core/profile/pending_financial_form_store.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/theme/tradex_colors.dart';
import '../../../core/theme/tradex_icons.dart';
import '../data/trade_ideas_repository.dart';
import '../data/market_news_warning_source.dart';
import '../data/learning_repository.dart';
import '../data/market_news_repository.dart';
import '../../profile/presentation/trusted_devices_screen.dart';
import '../../profile/presentation/mobile_number_details_screen.dart';
import '../../profile/presentation/withdrawal_method_screen.dart';
import '../../learn/domain/repositories/learn_repository.dart';
import '../../learn/learn_dependencies.dart';
import '../../learn/presentation/learn_module.dart';
import '../../market/presentation/crypto_market_screen.dart';
import '../../trade_ideas/data/trade_idea_repository.dart';
import '../../trade_ideas/presentation/trade_ideas_screen.dart';
import '../../trade_ideas/presentation/trade_idea_details_screen.dart';
import '../../auth/presentation/quick_unlock_settings_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../../affiliate/presentation/affiliate_module.dart';
import '../../affiliate/affiliate_dependencies.dart';
import '../../catalog/models/feature_spec.dart';
import '../../catalog/presentation/feature_catalog_screen.dart';
import 'bloc/home_navigation_cubit.dart';
import 'bloc/home_market_news_cubit.dart';

part 'home_dashboard/dashboard_shell.dart';
part 'home_dashboard/home_services_section.dart';
part 'home_dashboard/market_clock_section.dart';
part 'home_dashboard/market_news_section.dart';
part 'home_dashboard/home_learning_section.dart';
part 'home_dashboard/live_trade_ideas_section.dart';
part 'home_dashboard/latest_content_section.dart';
part 'home_dashboard/dashboard_tabs.dart';
part 'home_dashboard/profile_tab.dart';
part 'home_dashboard/profile_tab_state.dart';
part 'home_dashboard/profile_tab_models.dart';
part 'home_dashboard/learning_tab_widgets.dart';
part 'home_dashboard/trade_ideas_tab_widgets.dart';
part 'home_dashboard/affiliate_tab_widgets.dart';
part 'home_dashboard/dashboard_navigation.dart';
part 'home_dashboard/home_shared_widgets.dart';

bool _timeZoneDatabaseInitialized = false;

void _ensureTimeZoneDatabase() {
  if (_timeZoneDatabaseInitialized) return;
  tz_data.initializeTimeZones();
  _timeZoneDatabaseInitialized = true;
}
