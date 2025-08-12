import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';

/// Repositório para gerenciar os dados dos bares no Firestore
class BarRepository {
  final FirebaseFirestore _firestore;
  
  BarRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Referência para a coleção de bares
  CollectionReference<Map<String, dynamic>> get _barsCollection =>
      _firestore.collection(FirestoreKeys.barsCollection);
  
  /// Busca um bar pelo ID
  Future<BarModel?> getBarById(String id) async {
    try {
      final docSnapshot = await _barsCollection.doc(id).get();
      if (docSnapshot.exists) {
        return BarModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca um bar pelo e-mail
  Future<BarModel?> getBarByEmail(String email) async {
    try {
      final querySnapshot = await _barsCollection
          .where(FirestoreKeys.barEmail, isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return BarModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca um bar pelo CNPJ
  Future<BarModel?> getBarByCnpj(String cnpj) async {
    try {
      final querySnapshot = await _barsCollection
          .where(FirestoreKeys.barCnpj, isEqualTo: cnpj)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return BarModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Cria um novo bar
  Future<String> createBar(BarModel bar) async {
    try {
      final docRef = await _barsCollection.add(bar.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Atualiza um bar existente
  Future<void> updateBar(BarModel bar) async {
    try {
      await _barsCollection.doc(bar.id).update(bar.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  /// Exclui um bar
  Future<void> deleteBar(String id) async {
    try {
      await _barsCollection.doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Verifica se um e-mail já está em uso
  Future<bool> isEmailInUse(String email) async {
    try {
      final bar = await getBarByEmail(email);
      return bar != null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Verifica se um CNPJ já está em uso
  Future<bool> isCnpjInUse(String cnpj) async {
    try {
      final bar = await getBarByCnpj(cnpj);
      return bar != null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca um bar pelo ID do usuário
  Future<BarModel?> getBarByUserId(String userId) async {
    try {
      final querySnapshot = await _barsCollection
          .where(FirestoreKeys.barUserId, isEqualTo: userId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return BarModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}