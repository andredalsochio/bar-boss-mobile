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
    final createdAtData = data[FirestoreKeys.userCreatedAt];
    final lastLoginAtData = data[FirestoreKeys.userLastLoginAt];
    
    DateTime createdAt;
    if (createdAtData is Timestamp) {
      createdAt = createdAtData.toDate();
    } else if (createdAtData is DateTime) {
      createdAt = createdAtData;
    } else {
      createdAt = DateTime.now();
    }
    
    DateTime? lastLoginAt;
    if (lastLoginAtData is Timestamp) {
      lastLoginAt = lastLoginAtData.toDate();
    } else if (lastLoginAtData is DateTime) {
      lastLoginAt = lastLoginAtData;
    }
    
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
}