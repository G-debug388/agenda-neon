import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Cadastro e login 100% locais (sem Firebase), salvos com
/// shared_preferences. Funciona em Android, Web e Desktop.
class AuthService {
  static const _usersKey = 'agenda_neon.users';
  static const _sessionKey = 'agenda_neon.session';

  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static bool isValidEmail(String email) =>
      _emailRegex.hasMatch(email.trim().toLowerCase());

  static String hashPassword(String email, String password) =>
      sha256.convert(utf8.encode('$email::$password')).toString();

  Future<Map<String, AppUser>> _loadUsers(SharedPreferences prefs) async {
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (email, json) =>
          MapEntry(email, AppUser.fromJson(json as Map<String, dynamic>)),
    );
  }

  Future<void> _saveUsers(
    SharedPreferences prefs,
    Map<String, AppUser> users,
  ) async {
    await prefs.setString(
      _usersKey,
      jsonEncode(users.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.length < 2) {
      throw const AuthException('Informe seu nome.');
    }
    if (!isValidEmail(cleanEmail)) {
      throw const AuthException('E-mail inválido.');
    }
    if (password.length < 6) {
      throw const AuthException('A senha precisa ter ao menos 6 caracteres.');
    }

    final prefs = await SharedPreferences.getInstance();
    final users = await _loadUsers(prefs);
    if (users.containsKey(cleanEmail)) {
      throw const AuthException('Este e-mail já está cadastrado.');
    }

    final user = AppUser(
      name: cleanName,
      email: cleanEmail,
      passwordHash: hashPassword(cleanEmail, password),
    );
    users[cleanEmail] = user;
    await _saveUsers(prefs, users);
    return user;
  }

  Future<AppUser> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final users = await _loadUsers(prefs);
    final user = users[cleanEmail];

    if (user == null) {
      throw const AuthException('Nenhuma conta encontrada com este e-mail.');
    }
    if (user.passwordHash != hashPassword(cleanEmail, password)) {
      throw const AuthException('Senha incorreta. Tente novamente.');
    }

    await prefs.setString(_sessionKey, cleanEmail);
    return user;
  }

  /// Usuário com sessão ativa (para não precisar logar toda vez).
  Future<AppUser?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionKey);
    if (email == null) return null;
    final users = await _loadUsers(prefs);
    return users[email];
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
