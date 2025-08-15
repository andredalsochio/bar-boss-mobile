import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository_domain.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';
import 'package:bar_boss_mobile/app/data/adapters/bar_adapter.dart';

/// Implementação Firebase da interface BarRepositoryDomain
class FirebaseBarRepository implements BarRepositoryDomain {
  final FirebaseFirestore _firestore;
  
  FirebaseBarRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _barsCol =>
      _firestore.collection(FirestoreKeys.barsCollection);
  
  CollectionReference<Map<String, dynamic>> get _cnpjRegCol =>
      _firestore.collection(FirestoreKeys.cnpjRegistryCollection);

  /// Normaliza CNPJ removendo caracteres não numéricos
  String _normalizeCnpj(String cnpj) => cnpj.replaceAll(RegExp(r'[^0-9]'), '');
  
  /// Timestamp do servidor
  FieldValue get _now => FieldValue.serverTimestamp();

  @override
  Future<String> create(BarModel bar) async {
    final cnpj = _normalizeCnpj(bar.cnpj);
    final barId = _barsCol.doc().id;
    final ownerUid = bar.createdByUid;

    final batch = _firestore.batch();

    final cnpjRef = _cnpjRegCol.doc(cnpj);
    final barRef = _barsCol.doc(barId);
    final memberRef = barRef.collection(FirestoreKeys.membersSubcollection).doc(ownerUid);

    // 1) Reserva CNPJ
    batch.set(cnpjRef, {
      'barId': barId,
      'reservedByUid': ownerUid,
      'createdAt': _now,
    });

    // 2) Cria o bar
    final barWithIds = bar.copyWith(
      id: barId,
      cnpj: cnpj,
      createdAt: DateTime.now(), // será sobrescrito pelo _now
      updatedAt: DateTime.now(), // será sobrescrito pelo _now
      createdByUid: ownerUid,
    );
    final barData = BarAdapter.toFirestore(barWithIds)
      ..addAll({
        'createdAt': _now,
        'updatedAt': _now,
        'createdByUid': ownerUid,
      });

    batch.set(barRef, barData);

    // 3) Adiciona o criador como membro OWNER
    batch.set(memberRef, {
      'uid': ownerUid,
      'role': 'OWNER',
      'createdAt': _now,
      'barId': barId,
      'barName': bar.name,
    });

    await batch.commit();
    return barId;
  }

  @override
  Future<void> update(BarModel bar) async {
    try {
      await _barsCol.doc(bar.id).update(
        BarAdapter.toFirestore(bar)..addAll({'updatedAt': _now}),
      );
    } catch (e) {
      throw Exception('Erro ao atualizar bar: $e');
    }
  }

  @override
  Stream<List<BarModel>> listMyBars(String uid) {
    return _firestore
        .collectionGroup(FirestoreKeys.membersSubcollection)
        .where('uid', isEqualTo: uid)
        .snapshots()
        .asyncMap((membersSnap) async {
      final refs = membersSnap.docs
          .map((m) => m.reference.parent.parent!)
          .whereType<DocumentReference<Map<String, dynamic>>>()
          .toList();
      
      if (refs.isEmpty) return <BarModel>[];
      
      final bars = await Future.wait(refs.map((r) => r.get()));
      return bars
          .where((d) => d.exists)
          .map(BarAdapter.fromFirestore)
          .toList();
    });
  }

  @override
  Future<void> addMember(String barId, String uid, String role) async {
    try {
      final barRef = _barsCol.doc(barId);
      final memberRef = barRef.collection(FirestoreKeys.membersSubcollection).doc(uid);
      
      // Busca o nome do bar para desnormalizar
      final barDoc = await barRef.get();
      final barData = barDoc.data();
      final barName = barDoc.exists && barData != null ? barData['name'] ?? '' : '';
      
      await memberRef.set({
        'uid': uid,
        'role': role,
        'createdAt': _now,
        'barId': barId,
        'barName': barName,
      });
    } catch (e) {
      throw Exception('Erro ao adicionar membro: $e');
    }
  }
}