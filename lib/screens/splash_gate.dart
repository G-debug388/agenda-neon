import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/neon_background.dart';
import 'auth_screen.dart';
import 'calendar_screen.dart';

/// Primeira tela: verifica se existe uma sessão salva e decide se mostra
/// o calendário (usuário logado) ou a tela de login/cadastro.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  late final Future<AppUser?> _session = AuthService().currentUser();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: NeonBackground(child: Center(child: AppLogo(size: 110))),
          );
        }
        final user = snapshot.data;
        return user == null ? const AuthScreen() : CalendarScreen(user: user);
      },
    );
  }
}
