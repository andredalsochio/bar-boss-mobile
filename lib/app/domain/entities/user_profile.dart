import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';

/// Entidade de domínio para o perfil do usuário
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final List<String> providers;
  final String? currentBarId;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  /// Flag para indicar se o usuário completou o cadastro completo via "Não tem um bar?"
  /// true = usuário completou Passo 1 + Passo 2 + Criar Senha
  /// false = usuário fez login social e pode precisar completar perfil
  final bool completedFullRegistration;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.providers,
    this.currentBarId,
    required this.createdAt,
    this.lastLoginAt,
    this.completedFullRegistration = false,
  });

  /// Cria um UserProfile vazio
  factory UserProfile.empty(String uid, String email) {
    return UserProfile(
      uid: uid,
      email: email,
      providers: [],
      createdAt: DateTime.now(),
      completedFullRegistration: false,
    );
  }

  /// Cria um UserProfile a partir de dados mapeados
  factory UserProfile.fromMap(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      email: data[FirestoreKeys.userEmail] ?? '',
      displayName: data[FirestoreKeys.userDisplayName],
      photoUrl: data[FirestoreKeys.userPhotoUrl],
      providers: List<String>.from(data[FirestoreKeys.userProviders] ?? []),
      currentBarId: data[FirestoreKeys.userCurrentBarId],
      createdAt: data[FirestoreKeys.userCreatedAt] is DateTime
          ? data[FirestoreKeys.userCreatedAt]
          : DateTime.now(),
      lastLoginAt: data[FirestoreKeys.userLastLoginAt] is DateTime
          ? data[FirestoreKeys.userLastLoginAt]
          : null,
      completedFullRegistration: data[FirestoreKeys.userCompletedFullRegistration] ?? false,
    );
  }

  /// Converte o UserProfile para um Map para persistência
  Map<String, dynamic> toMap() {
    return {
      FirestoreKeys.userEmail: email,
      FirestoreKeys.userDisplayName: displayName,
      FirestoreKeys.userPhotoUrl: photoUrl,
      FirestoreKeys.userProviders: providers,
      FirestoreKeys.userCurrentBarId: currentBarId,
      FirestoreKeys.userCreatedAt: createdAt,
      FirestoreKeys.userLastLoginAt: lastLoginAt,
      FirestoreKeys.userCompletedFullRegistration: completedFullRegistration,
    };
  }

  /// Cria uma cópia do UserProfile com os campos atualizados
  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    List<String>? providers,
    String? currentBarId,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? completedFullRegistration,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      providers: providers ?? this.providers,
      currentBarId: currentBarId ?? this.currentBarId,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      completedFullRegistration: completedFullRegistration ?? this.completedFullRegistration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'UserProfile(uid: $uid, email: $email, displayName: $displayName)';
  }
}