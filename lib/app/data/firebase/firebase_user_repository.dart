import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bar_boss_mobile/app/domain/repositories/user_repository.dart';
import 'package:bar_boss_mobile/app/domain/entities/user_profile.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';

/// Implementação Firebase da interface UserRepository
class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Cache para evitar múltiplas operações simultâneas
  static final Map<String, Future<void>> _ongoingUpserts = {};
  static final Map<String, Future<UserProfile?>> _ongoingGets = {};
  
  /// Timestamp do servidor
  FieldValue get _now => FieldValue.serverTimestamp();

  /// Referência para a coleção de usuários
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreKeys.usersCollection);

  @override
  Future<UserProfile?> getMe() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('🔍 [DEBUG] UserRepository.getMe: Usuário não autenticado');
      return null;
    }

    final uid = currentUser.uid;
    
    // Verifica se já existe uma operação em andamento para este usuário
    if (_ongoingGets.containsKey(uid)) {
      debugPrint('🔄 [DEBUG] UserRepository.getMe: Operação já em andamento para uid=$uid, aguardando...');
      return await _ongoingGets[uid]!;
    }

    // Cria e armazena a operação
    final operation = _performGetMe(currentUser);
    _ongoingGets[uid] = operation;

    try {
      final result = await operation;
      return result;
    } finally {
      // Remove a operação do cache quando concluída
      _ongoingGets.remove(uid);
    }
  }

  /// Executa a operação real de getMe
  Future<UserProfile?> _performGetMe(User currentUser) async {
    try {
      debugPrint('🔍 [DEBUG] UserRepository.getMe: Buscando perfil para uid=${currentUser.uid}');
      final doc = await _usersCollection.doc(currentUser.uid).get();
      if (doc.exists) {
        final profile = _fromFirestore(doc);
        debugPrint('🔍 [DEBUG] UserRepository.getMe: Perfil encontrado - completedFullRegistration=${profile.completedFullRegistration}');
        return profile;
      }

      debugPrint('🔍 [DEBUG] UserRepository.getMe: Perfil não existe, criando perfil básico');
      // Se o documento não existe, cria um perfil básico baseado no Firebase Auth
      final profile = UserProfile(
        uid: currentUser.uid,
        email: currentUser.email ?? '',
        displayName: currentUser.displayName,
        photoUrl: currentUser.photoURL,
        providers: currentUser.providerData.map((p) => p.providerId).toList(),
        createdAt: currentUser.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: currentUser.metadata.lastSignInTime,
        completedFullRegistration: false, // Perfil básico sempre false
      );

      debugPrint('🔍 [DEBUG] UserRepository.getMe: Salvando perfil básico com completedFullRegistration=false');
      // Salva o perfil no Firestore
      await upsert(profile);
      return profile;
    } catch (e) {
      debugPrint('❌ [DEBUG] UserRepository.getMe: Erro - $e');
      throw Exception('Erro ao carregar perfil do usuário. Tente novamente.');
    }
  }

  @override
  Future<void> upsert(UserProfile data) async {
    final uid = data.uid;
    
    // Verifica se já existe uma operação em andamento para este usuário
    if (_ongoingUpserts.containsKey(uid)) {
      debugPrint('🔄 [DEBUG] UserRepository.upsert: Operação já em andamento para uid=$uid, aguardando...');
      return await _ongoingUpserts[uid]!;
    }

    // Cria e armazena a operação
    final operation = _performUpsert(data);
    _ongoingUpserts[uid] = operation;

    try {
      await operation;
    } finally {
      // Remove a operação do cache quando concluída
      _ongoingUpserts.remove(uid);
    }
  }

  /// Executa a operação real de upsert
  Future<void> _performUpsert(UserProfile data) async {
    try {
      debugPrint('🔍 [DEBUG] UserRepository.upsert: Salvando perfil uid=${data.uid}, completedFullRegistration=${data.completedFullRegistration}');
      final firestoreData = _toFirestore(data);
      
      // Verifica se o documento já existe para decidir se adiciona createdAt
      final docRef = _usersCollection.doc(data.uid);
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        // Documento existe, apenas atualiza com updatedAt
        debugPrint('🔍 [DEBUG] UserRepository.upsert: Documento existe, atualizando');
        firestoreData['updatedAt'] = _now;
      } else {
        // Documento novo, adiciona createdAt e updatedAt
        debugPrint('🔍 [DEBUG] UserRepository.upsert: Documento novo, criando');
        firestoreData['createdAt'] = _now;
        firestoreData['updatedAt'] = _now;
      }
      
      debugPrint('🔍 [DEBUG] UserRepository.upsert: Dados Firestore: $firestoreData');
      await docRef.set(
        firestoreData,
        SetOptions(merge: true),
      );
      debugPrint('✅ [DEBUG] UserRepository.upsert: Perfil salvo com sucesso');
    } catch (e) {
      debugPrint('❌ [DEBUG] UserRepository.upsert: Erro - $e');
      throw Exception('Erro ao salvar perfil do usuário. Tente novamente.');
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
      completedFullRegistration: data[FirestoreKeys.userCompletedFullRegistration] ?? false,
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
      FirestoreKeys.userCompletedFullRegistration: userProfile.completedFullRegistration,
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