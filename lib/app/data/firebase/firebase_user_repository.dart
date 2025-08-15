import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bar_boss_mobile/app/domain/repositories/user_repository.dart';
import 'package:bar_boss_mobile/app/domain/entities/user_profile.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';
import '../adapters/user_profile_adapter.dart';

/// Implementação Firebase da interface UserRepository
class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
        return UserProfileAdapter.fromFirestore(doc);
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
      final firestoreData = UserProfileAdapter.toFirestore(data);
      await _usersCollection.doc(data.uid).set(
        firestoreData,
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Erro ao salvar perfil do usuário: $e');
    }
  }
}