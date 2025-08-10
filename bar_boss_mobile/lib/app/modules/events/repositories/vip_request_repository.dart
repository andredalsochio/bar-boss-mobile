import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';
import 'package:bar_boss_mobile/app/modules/events/models/vip_request_model.dart';

/// Repositório para gerenciar as solicitações VIP no Firestore
class VipRequestRepository {
  final FirebaseFirestore _firestore;
  
  VipRequestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Referência para a coleção de solicitações VIP
  CollectionReference<Map<String, dynamic>> get _vipRequestsCollection =>
      _firestore.collection(FirestoreKeys.vipRequestsCollection);
  
  /// Busca uma solicitação VIP pelo ID
  Future<VipRequestModel?> getVipRequestById(String id) async {
    try {
      final docSnapshot = await _vipRequestsCollection.doc(id).get();
      if (docSnapshot.exists) {
        return VipRequestModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca todas as solicitações VIP de um evento
  Future<List<VipRequestModel>> getVipRequestsByEventId(String eventId) async {
    try {
      final querySnapshot = await _vipRequestsCollection
          .where(FirestoreKeys.eventId, isEqualTo: eventId)
          .orderBy(FirestoreKeys.createdAt, descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => VipRequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca todas as solicitações VIP de um bar
  Future<List<VipRequestModel>> getVipRequestsByBarId(String barId) async {
    try {
      final querySnapshot = await _vipRequestsCollection
          .where(FirestoreKeys.barId, isEqualTo: barId)
          .orderBy(FirestoreKeys.createdAt, descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => VipRequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca todas as solicitações VIP pendentes de um bar
  Future<List<VipRequestModel>> getPendingVipRequestsByBarId(String barId) async {
    try {
      final querySnapshot = await _vipRequestsCollection
          .where(FirestoreKeys.barId, isEqualTo: barId)
          .where(FirestoreKeys.vipRequestStatus, isEqualTo: VipRequestStatus.pending.name)
          .orderBy(FirestoreKeys.createdAt, descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => VipRequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca todas as solicitações VIP de um usuário
  Future<List<VipRequestModel>> getVipRequestsByUserId(String userId) async {
    try {
      final querySnapshot = await _vipRequestsCollection
          .where(FirestoreKeys.userId, isEqualTo: userId)
          .orderBy(FirestoreKeys.createdAt, descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => VipRequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Cria uma nova solicitação VIP
  Future<String> createVipRequest(VipRequestModel vipRequest) async {
    try {
      final docRef = await _vipRequestsCollection.add(vipRequest.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Atualiza uma solicitação VIP existente
  Future<void> updateVipRequest(VipRequestModel vipRequest) async {
    try {
      await _vipRequestsCollection.doc(vipRequest.id).update(vipRequest.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  /// Atualiza o status de uma solicitação VIP
  Future<void> updateVipRequestStatus(
    String id,
    VipRequestStatus status,
  ) async {
    try {
      await _vipRequestsCollection.doc(id).update({
        FirestoreKeys.vipRequestStatus: status.name,
        FirestoreKeys.updatedAt: Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      rethrow;
    }
  }
  
  /// Exclui uma solicitação VIP
  Future<void> deleteVipRequest(String id) async {
    try {
      await _vipRequestsCollection.doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Verifica se um usuário já fez uma solicitação VIP para um evento
  Future<bool> hasUserRequestedVip(
    String userId,
    String eventId,
  ) async {
    try {
      final querySnapshot = await _vipRequestsCollection
          .where(FirestoreKeys.userId, isEqualTo: userId)
          .where(FirestoreKeys.eventId, isEqualTo: eventId)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Conta o número de solicitações VIP pendentes para um bar
  Future<int> countPendingVipRequestsByBarId(String barId) async {
    try {
      final querySnapshot = await _vipRequestsCollection
          .where(FirestoreKeys.barId, isEqualTo: barId)
          .where(FirestoreKeys.vipRequestStatus, isEqualTo: VipRequestStatus.pending.name)
          .count()
          .get();
      
      return querySnapshot.count ?? 0;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Stream de solicitações VIP de um bar
  Stream<List<VipRequestModel>> streamVipRequestsByBarId(String barId) {
    return _vipRequestsCollection
        .where(FirestoreKeys.barId, isEqualTo: barId)
        .orderBy(FirestoreKeys.createdAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VipRequestModel.fromFirestore(doc))
            .toList());
  }
  
  /// Stream de solicitações VIP pendentes de um bar
  Stream<List<VipRequestModel>> streamPendingVipRequestsByBarId(String barId) {
    return _vipRequestsCollection
        .where(FirestoreKeys.barId, isEqualTo: barId)
        .where(FirestoreKeys.vipRequestStatus, isEqualTo: VipRequestStatus.pending.name)
        .orderBy(FirestoreKeys.createdAt, descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VipRequestModel.fromFirestore(doc))
            .toList());
  }
  
  /// Stream do contador de solicitações VIP pendentes de um bar
  Stream<int> streamPendingVipRequestsCountByBarId(String barId) {
    return _vipRequestsCollection
        .where(FirestoreKeys.barId, isEqualTo: barId)
        .where(FirestoreKeys.vipRequestStatus, isEqualTo: VipRequestStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}