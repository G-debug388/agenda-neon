import 'package:flutter/material.dart';

import 'screens/splash_gate.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgendaNeonApp());
}

class AgendaNeonApp extends StatelessWidget {
  const AgendaNeonApp({super.key, this.home});

  /// Permite trocar a tela inicial (usado nos testes).
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda Neon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: home ?? const SplashGate(),
    );
  }
}
