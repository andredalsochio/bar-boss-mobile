import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';
import 'package:bar_boss_mobile/app/modules/auth/models/user_model.dart';

/// Repositório para gerenciar os dados dos usuários no Firestore
class UserRepository {
  final FirebaseFirestore _firestore;
  
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Timestamp do servidor
  FieldValue get _now => FieldValue.serverTimestamp();
  
  /// Referência para a coleção de usuários
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreKeys.usersCollection);
  
  /// Busca um usuário pelo UID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final docSnapshot = await _usersCollection.doc(uid).get();
      if (docSnapshot.exists) {
        return UserModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca um usuário pelo e-mail
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _usersCollection
          .where(FirestoreKeys.userEmail, isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Cria um novo usuário
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(
        user.toFirestore()..addAll({
          'createdAt': _now,
          'updatedAt': _now,
        }),
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Atualiza um usuário existente
  Future<void> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).update(
        user.toFirestore()..addAll({'updatedAt': _now}),
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Atualiza o último login do usuário
  Future<void> updateLastLogin(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        FirestoreKeys.userLastLoginAt: _now,
        'updatedAt': _now,
      });
    } catch (e) {
      rethrow;
    }
  }
  
  /// Atualiza o bar atual do usuário
  Future<void> updateCurrentBar(String uid, String? barId) async {
    try {
      final data = <String, dynamic>{
        'updatedAt': _now,
      };
      if (barId != null) {
        data[FirestoreKeys.userCurrentBarId] = barId;
      } else {
        data[FirestoreKeys.userCurrentBarId] = FieldValue.delete();
      }
      
      await _usersCollection.doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Exclui um usuário
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Stream de um usuário específico
  Stream<UserModel?> streamUser(String uid) {
    return _usersCollection
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return UserModel.fromFirestore(snapshot);
          }
          return null;
        });
  }
  
  /// Verifica se um usuário existe
  Future<bool> userExists(String uid) async {
    try {
      final docSnapshot = await _usersCollection.doc(uid).get();
      return docSnapshot.exists;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca usuários por provider
  Future<List<UserModel>> getUsersByProvider(String provider) async {
    try {
      final querySnapshot = await _usersCollection
          .where(FirestoreKeys.userProviders, arrayContains: provider)
          .get();
      
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}