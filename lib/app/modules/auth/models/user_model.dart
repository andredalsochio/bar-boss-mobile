import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';

/// Modelo de dados para usuários no novo sistema multi-bar/multi-usuário
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final List<String> providers;
  final String? currentBarId;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.providers,
    this.currentBarId,
    required this.createdAt,
    required this.lastLoginAt,
  });

  /// Cria uma instância vazia com valores padrão
  factory UserModel.empty() {
    final now = DateTime.now();
    return UserModel(
      uid: '',
      email: '',
      displayName: null,
      photoUrl: null,
      providers: [],
      currentBarId: null,
      createdAt: now,
      lastLoginAt: now,
    );
  }

  /// Cria uma instância a partir de um documento do Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data[FirestoreKeys.userEmail] ?? '',
      displayName: data[FirestoreKeys.userDisplayName],
      photoUrl: data[FirestoreKeys.userPhotoUrl],
      providers: List<String>.from(data[FirestoreKeys.userProviders] ?? []),
      currentBarId: data[FirestoreKeys.userCurrentBarId],
      createdAt: (data[FirestoreKeys.userCreatedAt] as Timestamp).toDate(),
      lastLoginAt: (data[FirestoreKeys.userLastLoginAt] as Timestamp).toDate(),
    );
  }

  /// Converte o modelo para um mapa para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      FirestoreKeys.userEmail: email,
      if (displayName != null) FirestoreKeys.userDisplayName: displayName,
      if (photoUrl != null) FirestoreKeys.userPhotoUrl: photoUrl,
      FirestoreKeys.userProviders: providers,
      if (currentBarId != null) FirestoreKeys.userCurrentBarId: currentBarId,
      FirestoreKeys.userCreatedAt: Timestamp.fromDate(createdAt),
      FirestoreKeys.userLastLoginAt: Timestamp.fromDate(lastLoginAt),
    };
  }

  /// Cria uma cópia do modelo com campos atualizados
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    List<String>? providers,
    String? currentBarId,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      providers: providers ?? this.providers,
      currentBarId: currentBarId ?? this.currentBarId,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, currentBarId: $currentBarId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}