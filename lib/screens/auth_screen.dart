import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/gradient_button.dart';
import '../widgets/neon_background.dart';
import 'calendar_screen.dart';

/// Tela única de Login e Cadastro, com uma chave animada para alternar
/// entre os dois modos.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _setMode(bool login) {
    if (login == _isLogin) return;
    setState(() {
      _isLogin = login;
      _formKey = GlobalKey<FormState>(); // limpa mensagens de erro antigas
    });
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: error ? AppColors.danger : AppColors.ink,
          content: Row(
            children: [
              Icon(
                error ? Icons.error_outline_rounded : Icons.celebration_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      if (_isLogin) {
        final user = await _auth.login(_email.text, _password.text);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => CalendarScreen(user: user)),
        );
      } else {
        await _auth.register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
        if (!mounted) return;
        _password.clear();
        _confirm.clear();
        setState(() {
          _isLogin = true;
          _formKey = GlobalKey<FormState>();
        });
        _showSnack('Conta criada com sucesso! Agora é só entrar.');
      }
    } on AuthException catch (e) {
      if (mounted) _showSnack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    const AppLogo(),
                    const SizedBox(height: 22),
                    const Text(
                      'Agenda Neon',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLogin
                          ? 'Que bom te ver de novo! Entre para ver seus dias.'
                          : 'Crie sua conta e dê cor à sua rotina.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _buildCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModeSwitch(isLogin: _isLogin, onChanged: _setMode),
            const SizedBox(height: 22),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _isLogin
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextFormField(
                        key: const Key('field_name'),
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                        validator: (v) => (v ?? '').trim().length < 2
                            ? 'Informe seu nome'
                            : null,
                      ),
                    ),
            ),
            TextFormField(
              key: const Key('field_email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (v) =>
                  AuthService.isValidEmail(v ?? '') ? null : 'E-mail inválido',
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('field_password'),
              controller: _password,
              obscureText: _obscure,
              textInputAction: _isLogin
                  ? TextInputAction.done
                  : TextInputAction.next,
              onFieldSubmitted: (_) {
                if (_isLogin) _submit();
              },
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: AppColors.violet,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                final value = v ?? '';
                if (value.isEmpty) return 'Informe sua senha';
                if (!_isLogin && value.length < 6) {
                  return 'A senha precisa ter ao menos 6 caracteres';
                }
                return null;
              },
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _isLogin
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: TextFormField(
                        key: const Key('field_confirm'),
                        controller: _confirm,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Confirmar senha',
                          prefixIcon: Icon(Icons.lock_reset_rounded),
                        ),
                        validator: (v) => v != _password.text
                            ? 'As senhas não conferem'
                            : null,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              key: const Key('btn_submit'),
              label: _isLogin ? 'Entrar' : 'Cadastrar',
              icon: _isLogin
                  ? Icons.arrow_forward_rounded
                  : Icons.person_add_alt_1_rounded,
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 6),
            TextButton(
              key: const Key('btn_toggle_mode'),
              onPressed: () => _setMode(!_isLogin),
              style: TextButton.styleFrom(foregroundColor: AppColors.violet),
              child: Text.rich(
                TextSpan(
                  text: _isLogin ? 'Não tem conta? ' : 'Já tem conta? ',
                  style: TextStyle(color: AppColors.ink.withValues(alpha: 0.6)),
                  children: [
                    TextSpan(
                      text: _isLogin ? 'Cadastre-se' : 'Entre aqui',
                      style: const TextStyle(
                        color: AppColors.magenta,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.magenta,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chave "Entrar | Cadastrar" com uma pílula em degradê que desliza.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.isLogin, required this.onChanged});

  final bool isLogin;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Row(
            children: [
              _tab('Entrar', 'tab_login', selected: isLogin, value: true),
              _tab(
                'Cadastrar',
                'tab_register',
                selected: !isLogin,
                value: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tab(
    String label,
    String key, {
    required bool selected,
    required bool value,
  }) {
    return Expanded(
      child: GestureDetector(
        key: Key(key),
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(value),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: selected ? Colors.white : AppColors.violet,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
