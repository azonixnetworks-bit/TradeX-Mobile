
import 'package:flutter/material.dart';

import 'features/auth/presentation/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SplashPreviewApp());
}

class SplashPreviewApp extends StatelessWidget {
  const SplashPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      home: SplashScreen(),
    );
  }
}
