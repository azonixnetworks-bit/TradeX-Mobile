import 'package:flutter/material.dart';

import '../core/theme/tradex_theme.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/session_gate.dart';

class TradeXApp extends StatelessWidget {
  const TradeXApp({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TradeX',
      debugShowCheckedModeBanner: false,
      theme: TradeXTheme.dark,
      home: SessionGate(authRepository: authRepository),
    );
  }
}
