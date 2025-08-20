import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bar_boss_mobile/app/domain/repositories/user_repository.dart';
import 'package:bar_boss_mobile/app/domain/entities/user_profile.dart';
import 'package:bar_boss_mobile/app/core/schema/firestore_keys.dart';

/// Implementação Firebase da interface UserRepository
class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Timestamp do servidor
  FieldValue get _now => FieldValue.serverTimestamp();

  /// Referência para a coleção de usuários
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreKeys.usersCollection);

  @override
  Future<UserProfile?> getMe() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      final doc = await _usersCollection.doc(currentUser.uid).get();
      if (doc.exists) {
        return _fromFirestore(doc);
      }

      // Se o documento não existe, cria um perfil básico baseado no Firebase Auth
      final profile = UserProfile(
        uid: currentUser.uid,
        email: currentUser.email ?? '',
        displayName: currentUser.displayName,
        photoUrl: currentUser.photoURL,
        providers: currentUser.providerData.map((p) => p.providerId).toList(),
        createdAt: currentUser.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: currentUser.metadata.lastSignInTime,
      );

      // Salva o perfil no Firestore
      await upsert(profile);
      return profile;
    } catch (e) {
      throw Exception('Erro ao buscar perfil do usuário: $e');
    }
  }

  @override
  Future<void> upsert(UserProfile data) async {
    try {
      final firestoreData = _toFirestore(data);
      
      // Verifica se o documento já existe para decidir se adiciona createdAt
      final docRef = _usersCollection.doc(data.uid);
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        // Documento existe, apenas atualiza com updatedAt
        firestoreData['updatedAt'] = _now;
      } else {
        // Documento novo, adiciona createdAt e updatedAt
        firestoreData['createdAt'] = _now;
        firestoreData['updatedAt'] = _now;
      }
      
      await docRef.set(
        firestoreData,
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Erro ao salvar perfil do usuário: $e');
    }
  }

  // Métodos privados de conversão (anteriormente no UserProfileAdapter)
  
  /// Converte DocumentSnapshot do Firestore para UserProfile
  UserProfile _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
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
  Map<String, dynamic> _toFirestore(UserProfile userProfile) {
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
  DateTime _timestampToDateTime(dynamic timestamp) {
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
  DateTime? _timestampToDateTimeNullable(dynamic timestamp) {
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