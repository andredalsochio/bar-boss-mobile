/// Entidade de domínio para usuário autenticado
/// Substitui o tipo User do Firebase para manter isolamento
class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final List<String> providerIds;

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.emailVerified,
    required this.providerIds,
  });

  /// Cria um AuthUser vazio para estados não autenticados
  factory AuthUser.empty() {
    return const AuthUser(
      uid: '',
      emailVerified: false,
      providerIds: [],
    );
  }

  /// Verifica se o usuário está autenticado
  bool get isAuthenticated => uid.isNotEmpty;

  /// Verifica se o usuário tem um provedor específico
  bool hasProvider(String providerId) => providerIds.contains(providerId);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUser &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.emailVerified == emailVerified;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        photoUrl.hashCode ^
        emailVerified.hashCode;
  }

  @override
  String toString() {
    return 'AuthUser(uid: $uid, email: $email, displayName: $displayName, emailVerified: $emailVerified)';
  }
}