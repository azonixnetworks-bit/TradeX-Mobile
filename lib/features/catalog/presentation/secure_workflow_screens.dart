import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/bloc/bloc_future_builder.dart';
import '../../../core/domain/api_gateway.dart';
import '../../../core/domain/user_facing_exception.dart';
import '../../../core/theme/tradex_colors.dart';
import '../../secure_workflows/domain/services/secure_workflow_platform.dart';

part 'secure_workflows/kyc_submission_screen.dart';
part 'secure_workflows/payment_proof_screen.dart';
part 'secure_workflows/contact_change_screen.dart';
part 'secure_workflows/secure_workflow_entries.dart';
part 'secure_workflows/payment_checkout_state.dart';
part 'secure_workflows/copy_trade_dashboard_state.dart';
part 'secure_workflows/broker_connection_state.dart';
part 'secure_workflows/secure_workflow_shared_widgets.dart';
