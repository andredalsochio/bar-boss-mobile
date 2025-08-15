import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/cnpj_registry_model.dart';

/// Repositório para gerenciar o registro de CNPJs no Firestore
/// Usado para evitar duplicação de CNPJs entre bares
class CnpjRegistryRepository {
  final FirebaseFirestore _firestore;
  
  CnpjRegistryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Timestamp do servidor
  FieldValue get _now => FieldValue.serverTimestamp();
  
  /// Referência para a coleção de registro de CNPJs
  CollectionReference<Map<String, dynamic>> get _cnpjRegistryCollection =>
      _firestore.collection(FirestoreKeys.cnpjRegistryCollection);
  
  /// Busca um registro de CNPJ
  Future<CnpjRegistryModel?> getCnpjRegistry(String cnpj) async {
    try {
      final docSnapshot = await _cnpjRegistryCollection.doc(cnpj).get();
      if (docSnapshot.exists) {
        return CnpjRegistryModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Verifica se um CNPJ já está registrado
  Future<bool> isCnpjRegistered(String cnpj) async {
    try {
      final registry = await getCnpjRegistry(cnpj);
      return registry != null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Registra um novo CNPJ
  Future<void> registerCnpj(CnpjRegistryModel registry) async {
    try {
      await _cnpjRegistryCollection.doc(registry.cnpj).set(registry.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  /// Atualiza um registro de CNPJ existente
  Future<void> updateCnpjRegistry(CnpjRegistryModel registry) async {
    try {
      await _cnpjRegistryCollection.doc(registry.cnpj).update(registry.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  /// Remove um registro de CNPJ
  Future<void> removeCnpjRegistry(String cnpj) async {
    try {
      await _cnpjRegistryCollection.doc(cnpj).delete();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca todos os CNPJs registrados por um usuário
  Future<List<CnpjRegistryModel>> getCnpjsByUserId(String uid) async {
    try {
      final querySnapshot = await _cnpjRegistryCollection
          .where(FirestoreKeys.cnpjRegistryReservedByUid, isEqualTo: uid)
          .orderBy(FirestoreKeys.cnpjRegistryCreatedAt, descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => CnpjRegistryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca o registro de CNPJ por barId
  Future<CnpjRegistryModel?> getCnpjByBarId(String barId) async {
    try {
      final querySnapshot = await _cnpjRegistryCollection
          .where(FirestoreKeys.cnpjRegistryBarId, isEqualTo: barId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return CnpjRegistryModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Verifica se um usuário pode usar um CNPJ específico
  /// (se não está registrado ou se foi registrado por ele mesmo)
  Future<bool> canUseCnpj(String cnpj, String uid) async {
    try {
      final registry = await getCnpjRegistry(cnpj);
      
      // Se não está registrado, pode usar
      if (registry == null) return true;
      
      // Se foi registrado pelo mesmo usuário, pode usar
      return registry.reservedByUid == uid;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Reserva um CNPJ para um usuário (usado durante o processo de registro)
  Future<void> reserveCnpj(String cnpj, String uid) async {
    try {
      final registry = CnpjRegistryModel(
        cnpj: cnpj,
        barId: '', // Será preenchido quando o bar for criado
        reservedByUid: uid,
        createdAt: DateTime.now(), // será sobrescrito pelo _now
      );
      
      // Sobrescreve o createdAt com timestamp do servidor
      final data = registry.toFirestore();
      data['createdAt'] = _now;
      
      await _cnpjRegistryCollection.doc(cnpj).set(data);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Confirma o registro do CNPJ com o barId
  Future<void> confirmCnpjRegistration(String cnpj, String barId) async {
    try {
      await _cnpjRegistryCollection.doc(cnpj).update({
        FirestoreKeys.cnpjRegistryBarId: barId,
        'updatedAt': _now,
      });
    } catch (e) {
      rethrow;
    }
  }
  
  /// Libera um CNPJ reservado (usado se o registro do bar falhar)
  Future<void> releaseCnpj(String cnpj) async {
    try {
      await removeCnpjRegistry(cnpj);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Stream de registros de CNPJ de um usuário
  Stream<List<CnpjRegistryModel>> streamCnpjsByUserId(String uid) {
    return _cnpjRegistryCollection
        .where(FirestoreKeys.cnpjRegistryReservedByUid, isEqualTo: uid)
        .orderBy(FirestoreKeys.cnpjRegistryCreatedAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CnpjRegistryModel.fromFirestore(doc))
            .toList());
  }
  
  /// Conta quantos CNPJs um usuário tem registrado
  Future<int> getCnpjCountByUserId(String uid) async {
    try {
      final querySnapshot = await _cnpjRegistryCollection
          .where(FirestoreKeys.cnpjRegistryReservedByUid, isEqualTo: uid)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca registros de CNPJ criados em um período específico
  Future<List<CnpjRegistryModel>> getCnpjsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _cnpjRegistryCollection
          .where(FirestoreKeys.cnpjRegistryCreatedAt,
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where(FirestoreKeys.cnpjRegistryCreatedAt,
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy(FirestoreKeys.cnpjRegistryCreatedAt, descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => CnpjRegistryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}