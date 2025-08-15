import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/member_model.dart';

/// Repositório para gerenciar os membros dos bares no Firestore
/// Membros são subcoleções de bares: /bars/{barId}/members/{uid}
class MemberRepository {
  final FirebaseFirestore _firestore;
  
  MemberRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Referência para a subcoleção de membros de um bar específico
  CollectionReference<Map<String, dynamic>> _membersCollection(String barId) =>
      _firestore
          .collection(FirestoreKeys.barsCollection)
          .doc(barId)
          .collection(FirestoreKeys.membersSubcollection);
  
  /// Busca um membro específico de um bar
  Future<MemberModel?> getMember(String barId, String uid) async {
    try {
      final docSnapshot = await _membersCollection(barId).doc(uid).get();
      if (docSnapshot.exists) {
        return MemberModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca todos os membros de um bar
  Future<List<MemberModel>> getMembersByBarId(String barId) async {
    try {
      final querySnapshot = await _membersCollection(barId)
          .orderBy(FirestoreKeys.memberCreatedAt, descending: false)
          .get();
      
      return querySnapshot.docs
          .map((doc) => MemberModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca membros por role
  Future<List<MemberModel>> getMembersByRole(String barId, MemberRole role) async {
    try {
      final querySnapshot = await _membersCollection(barId)
          .where(FirestoreKeys.memberRole, isEqualTo: role.value)
          .orderBy(FirestoreKeys.memberCreatedAt, descending: false)
          .get();
      
      return querySnapshot.docs
          .map((doc) => MemberModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca todos os proprietários de um bar
  Future<List<MemberModel>> getOwners(String barId) async {
    return getMembersByRole(barId, MemberRole.owner);
  }
  
  /// Busca todos os administradores de um bar
  Future<List<MemberModel>> getAdmins(String barId) async {
    return getMembersByRole(barId, MemberRole.admin);
  }
  
  /// Busca todos os editores de um bar
  Future<List<MemberModel>> getEditors(String barId) async {
    return getMembersByRole(barId, MemberRole.editor);
  }
  
  /// Adiciona um novo membro ao bar
  Future<void> addMember(String barId, MemberModel member) async {
    try {
      await _membersCollection(barId).doc(member.uid).set(member.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  /// Atualiza um membro existente
  Future<void> updateMember(String barId, MemberModel member) async {
    try {
      await _membersCollection(barId).doc(member.uid).update(member.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  /// Atualiza apenas o role de um membro
  Future<void> updateMemberRole(String barId, String uid, MemberRole role) async {
    try {
      await _membersCollection(barId).doc(uid).update({
        FirestoreKeys.memberRole: role.value,
      });
    } catch (e) {
      rethrow;
    }
  }
  
  /// Remove um membro do bar
  Future<void> removeMember(String barId, String uid) async {
    try {
      await _membersCollection(barId).doc(uid).delete();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Verifica se um usuário é membro de um bar
  Future<bool> isMember(String barId, String uid) async {
    try {
      final docSnapshot = await _membersCollection(barId).doc(uid).get();
      return docSnapshot.exists;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Verifica se um usuário tem permissão específica em um bar
  Future<bool> hasPermission(String barId, String uid, MemberRole requiredRole) async {
    try {
      final member = await getMember(barId, uid);
      if (member == null) return false;
      
      // Proprietários têm todas as permissões
      if (member.role == MemberRole.owner) return true;
      
      // Administradores podem fazer tudo exceto gerenciar proprietários
      if (member.role == MemberRole.admin && requiredRole != MemberRole.owner) {
        return true;
      }
      
      // Editores só podem editar conteúdo
      if (member.role == MemberRole.editor && requiredRole == MemberRole.editor) {
        return true;
      }
      
      return false;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Stream de membros de um bar
  Stream<List<MemberModel>> streamMembersByBarId(String barId) {
    return _membersCollection(barId)
        .orderBy(FirestoreKeys.memberCreatedAt, descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MemberModel.fromFirestore(doc))
            .toList());
  }
  
  /// Stream de um membro específico
  Stream<MemberModel?> streamMember(String barId, String uid) {
    return _membersCollection(barId)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return MemberModel.fromFirestore(snapshot);
          }
          return null;
        });
  }
  
  /// Busca todos os bares onde um usuário é membro
  Future<List<String>> getBarIdsByUserId(String uid) async {
    try {
      // Como não podemos fazer query em subcoleções diretamente,
      // precisamos usar collection group query
      final querySnapshot = await _firestore
          .collectionGroup(FirestoreKeys.membersSubcollection)
          .where(FirestoreKeys.memberUid, isEqualTo: uid)
          .get();
      
      return querySnapshot.docs
          .map((doc) => doc.reference.parent.parent!.id)
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Conta o número de membros de um bar
  Future<int> getMemberCount(String barId) async {
    try {
      final querySnapshot = await _membersCollection(barId).get();
      return querySnapshot.docs.length;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Conta membros por role
  Future<int> getMemberCountByRole(String barId, MemberRole role) async {
    try {
      final querySnapshot = await _membersCollection(barId)
          .where(FirestoreKeys.memberRole, isEqualTo: role.value)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      rethrow;
    }
  }
}