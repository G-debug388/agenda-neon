/// Usuário cadastrado localmente. A senha nunca é guardada em texto puro,
/// apenas o hash SHA-256 gerado pelo AuthService.
class AppUser {
  const AppUser({
    required this.name,
    required this.email,
    required this.passwordHash,
  });

  final String name;
  final String email;
  final String passwordHash;

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? name : parts.first;
  }

  String get initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'passwordHash': passwordHash,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    name: json['name'] as String,
    email: json['email'] as String,
    passwordHash: json['passwordHash'] as String,
  );
}
