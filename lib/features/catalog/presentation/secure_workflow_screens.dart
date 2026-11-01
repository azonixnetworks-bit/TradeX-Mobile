import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/bloc/bloc_future_builder.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/tradex_api_client.dart';
import '../../../core/theme/tradex_colors.dart';

part 'secure_workflows/kyc_submission_screen.dart';
part 'secure_workflows/payment_proof_screen.dart';
part 'secure_workflows/contact_change_screen.dart';
part 'secure_workflows/secure_workflow_entries.dart';
part 'secure_workflows/payment_checkout_state.dart';
part 'secure_workflows/copy_trade_dashboard_state.dart';
part 'secure_workflows/broker_connection_state.dart';
part 'secure_workflows/secure_workflow_shared_widgets.dart';
