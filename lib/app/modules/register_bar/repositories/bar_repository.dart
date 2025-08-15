import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';
import 'package:bar_boss_mobile/app/data/adapters/bar_adapter.dart';

class BarRepository {
  final FirebaseFirestore _firestore;
  BarRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _barsCol =>
      _firestore.collection(FirestoreKeys.barsCollection); // "bars"
  CollectionReference<Map<String, dynamic>> get _cnpjRegCol =>
      _firestore.collection(FirestoreKeys.cnpjRegistryCollection); // "cnpj_registry"

  // ---------------------------
  // AUX
  // ---------------------------
  String _normalizeCnpj(String cnpj) => cnpj.replaceAll(RegExp(r'\D'), '');
  FieldValue get _now => FieldValue.serverTimestamp();

  // ---------------------------
  // CREATE (com reserva + membership OWNER)
  // ---------------------------
  /// Cria a reserva em `/cnpj_registry/{cnpj}`, cria o bar em `/bars/{barId}`
  /// e adiciona o membro OWNER em `/bars/{barId}/members/{uid}` – tudo no MESMO batch.
  Future<String> createBarWithReservation({
    required BarModel bar,
    required String ownerUid,
    String? forcedBarId,
  }) async {
    final cnpj = _normalizeCnpj(bar.cnpj);
    final barId = forcedBarId ?? _barsCol.doc().id;

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

    // 2) Bar
    final barData = BarAdapter.toFirestore(bar.copyWith(
      id: barId,
      cnpj: cnpj,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdByUid: ownerUid,
      // profile.contactsComplete/addressComplete devem refletir os passos,
      // ajuste conforme sua UI nesse momento.
    ))
      ..addAll({'createdAt': _now, 'updatedAt': _now, 'createdByUid': ownerUid});

    batch.set(barRef, barData);

    // 3) Membership OWNER
    batch.set(memberRef, {
      'uid': ownerUid,
      'role': 'OWNER',
      'createdAt': _now,
      // opcional: denormalize para facilitar queries rápidos sem join:
      'barId': barId,
      'barName': bar.name,
    });

    await batch.commit();
    return barId;
  }

  // ---------------------------
  // READ (compatível com as regras: via membership)
  // ---------------------------

  /// Retorna um bar por ID (funciona se o usuário atual for membro conforme regras).
  Future<BarModel?> getBarById(String id) async {
    try {
      final doc = await _barsCol.doc(id).get();
      return doc.exists ? BarAdapter.fromFirestore(doc) : null;
    } catch (e) {
      rethrow;
    }
  }

  /// Lista os bares em que o usuário é membro (fetch por collectionGroup('members')).
  Future<List<BarModel>> listBarsByMembership(String uid) async {
    final membersSnap = await _firestore
        .collectionGroup(FirestoreKeys.membersSubcollection) // "members"
        .where('uid', isEqualTo: uid)
        .get();

    // parent.parent! é o doc do bar
    final barDocRefs = membersSnap.docs
        .map((m) => m.reference.parent.parent!)
        .whereType<DocumentReference<Map<String, dynamic>>>()
        .toList();

    if (barDocRefs.isEmpty) return [];

    final bars = await Future.wait(barDocRefs.map((ref) => ref.get()));
    return bars.where((d) => d.exists).map(BarAdapter.fromFirestore).toList();
  }

  /// Stream dos bares do usuário (membro).
  Stream<List<BarModel>> streamBarsByMembership(String uid) {
    // Estratégia: escutar members e, a cada mudança, fazer fan-out para buscar os bars.
    // Para simplificar aqui, usamos asyncMap.
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
    return bars.where((d) => d.exists).map(BarAdapter.fromFirestore).toList();
    });
  }

  // ---------------------------
  // UPDATE / DELETE (mantidos)
  // ---------------------------

  Future<void> updateBar(BarModel bar) async {
    try {
      await _barsCol.doc(bar.id).update(BarAdapter.toFirestore(bar)..addAll({'updatedAt': _now}));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBarFields(String barId, Map<String, dynamic> fields) async {
    try {
      fields['updatedAt'] = _now;
      await _barsCol.doc(barId).update(fields);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBar(String id) async {
    // Observação: a remoção em cascata (members/events/cnpj_registry) recomenda-se via Cloud Function.
    try {
      await _barsCol.doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------
  // MÉTODOS LEGADOS (evitar usar com as novas regras)
  // ---------------------------

  @Deprecated('Evite: leitura por CNPJ em /bars não é permitida sob as novas regras.')
  Future<BarModel?> getBarByCnpj(String cnpj) async {
    throw UnimplementedError('Use createBarWithReservation() e membership.');
  }

  @Deprecated('Evite: leitura por e-mail em /bars não é permitida sob as novas regras.')
  Future<BarModel?> getBarByContactEmail(String contactEmail) async {
    throw UnimplementedError('Use membership para descobrir bares do usuário.');
  }

  @Deprecated('Evite: a unicidade de CNPJ deve ser garantida pela reserva em /cnpj_registry.')
  Future<bool> isCnpjInUse(String cnpj) async {
    throw UnimplementedError('A verificação agora é por tentativa de reserva no batch.');
  }

  // Mantidos por compatibilidade, mas prefira versões "byMembership"
  Future<List<BarModel>> getBarsByCreatedByUid(String uid) async {
    final snap = await _barsCol
        .where('createdByUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(BarAdapter.fromFirestore).toList();
  }

  Stream<BarModel?> streamBar(String barId) {
    return _barsCol.doc(barId).snapshots().map((s) => s.exists ? BarAdapter.fromFirestore(s) : null);
  }

  Future<void> updateBarStatus(String barId, String status) =>
      updateBarFields(barId, {'status': status});

  Future<void> updatePrimaryOwner(String barId, String newOwnerUid) =>
      updateBarFields(barId, {'primaryOwnerUid': newOwnerUid});

  Future<int> getBarCountByCreatedByUid(String uid) async {
    final q = await _barsCol.where('createdByUid', isEqualTo: uid).get();
    return q.docs.length;
  }

  Future<List<BarModel>> getBarsByDateRange(DateTime start, DateTime end) async {
    final q = await _barsCol
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: true)
        .get();
    return q.docs.map(BarAdapter.fromFirestore).toList();
  }

  // Removi createBar/createBarWithGeneratedId para desencorajar criação sem reserva/membership.
  // Se precisar manter por compatibilidade, marque-os como @Deprecated e encaminhe para createBarWithReservation().
}