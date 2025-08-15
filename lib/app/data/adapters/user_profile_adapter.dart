import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/domain/entities/user_profile.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';

/// Adapter para converter entre DocumentSnapshot do Firestore e UserProfile de domínio
class UserProfileAdapter {
  /// Converte DocumentSnapshot do Firestore para UserProfile de domínio
  static UserProfile? fromFirestore(DocumentSnapshot<Map<String, dynamic>>? doc) {
    if (doc == null || !doc.exists || doc.data() == null) return null;
    
    final data = doc.data()!;
    
    // Converte Timestamp para DateTime se necessário
    final createdAt = _timestampToDateTime(data[FirestoreKeys.userCreatedAt]);
    final lastLoginAt = _timestampToDateTimeNullable(data[FirestoreKeys.userLastLoginAt]);
    
    return UserProfile(
      uid: doc.id,
      email: data[FirestoreKeys.userEmail] ?? '',
      displayName: data[FirestoreKeys.userDisplayName],
      photoUrl: data[FirestoreKeys.userPhotoUrl],
      providers: List<String>.from(data[FirestoreKeys.userProviders] ?? []),
      currentBarId: data[FirestoreKeys.userCurrentBarId],
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  /// Converte UserProfile de domínio para Map do Firestore
  static Map<String, dynamic> toFirestore(UserProfile userProfile) {
    return {
      FirestoreKeys.userEmail: userProfile.email,
      FirestoreKeys.userDisplayName: userProfile.displayName,
      FirestoreKeys.userPhotoUrl: userProfile.photoUrl,
      FirestoreKeys.userProviders: userProfile.providers,
      FirestoreKeys.userCurrentBarId: userProfile.currentBarId,
      FirestoreKeys.userCreatedAt: Timestamp.fromDate(userProfile.createdAt),
      FirestoreKeys.userLastLoginAt: userProfile.lastLoginAt != null
          ? Timestamp.fromDate(userProfile.lastLoginAt!)
          : null,
    };
  }

  /// Converte Timestamp para DateTime
  /// Trata adequadamente valores null que podem ocorrer nos primeiros snapshots
  /// quando FieldValue.serverTimestamp() ainda não foi processado pelo servidor
  static DateTime _timestampToDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is DateTime) {
      return timestamp;
    }
    if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    // Retorna data atual se timestamp for null (primeiro snapshot)
    // ou se for de tipo inesperado
    return DateTime.now();
  }

  /// Converte Timestamp para DateTime nullable
  /// Retorna null se o valor for null ou inválido
  static DateTime? _timestampToDateTimeNullable(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is DateTime) {
      return timestamp;
    }
    if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    // Retorna null se timestamp for null ou de tipo inesperado
    return null;
  }
}