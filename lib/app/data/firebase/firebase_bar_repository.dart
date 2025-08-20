import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository_domain.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';
import 'package:bar_boss_mobile/app/core/schema/firestore_keys.dart';

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
    final barData = _toFirestore(barWithIds)
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
        _toFirestore(bar)..addAll({'updatedAt': _now}),
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
          .map((doc) => _fromFirestore(doc))
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

  // Métodos privados de conversão (anteriormente no BarAdapter)
  
  /// Converte DocumentSnapshot do Firestore para BarModel
  BarModel _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    return BarModel(
      id: doc.id,
      name: data['name'] ?? '',
      cnpj: data['cnpj'] ?? '',
      responsibleName: data['responsibleName'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      address: data['address'] != null 
          ? BarAddress.fromMap(data['address'])
          : BarAddress.empty(),
      profile: data['profile'] != null 
          ? BarProfile.fromMap(data['profile'])
          : BarProfile.empty(),
      status: data['status'] ?? 'active',
      logoUrl: data['logoUrl'],
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
      createdByUid: data['createdByUid'] ?? '',
      primaryOwnerUid: data['primaryOwnerUid'],
    );
  }

  /// Converte BarModel para Map do Firestore
  Map<String, dynamic> _toFirestore(BarModel bar) {
    return {
      'name': bar.name,
      'cnpj': bar.cnpj,
      'responsibleName': bar.responsibleName,
      'contactEmail': bar.contactEmail,
      'contactPhone': bar.contactPhone,
      'address': bar.address.toMap(),
      'profile': bar.profile.toMap(),
      'status': bar.status,
      'logoUrl': bar.logoUrl,
      'createdAt': bar.createdAt,
      'updatedAt': bar.updatedAt,
      'createdByUid': bar.createdByUid,
      'primaryOwnerUid': bar.primaryOwnerUid,
    };
  }

  /// Converte Timestamp para DateTime
  /// Trata adequadamente valores null que podem ocorrer nos primeiros snapshots
  /// quando FieldValue.serverTimestamp() ainda não foi processado pelo servidor
  DateTime _timestampToDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    // Retorna data atual se timestamp for null (primeiro snapshot)
    // ou se for de tipo inesperado
    return DateTime.now();
  }
}