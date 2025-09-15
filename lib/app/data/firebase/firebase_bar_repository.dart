import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
  @Deprecated('Use createBarWithReservation para operações atômicas')
  Future<String> create(BarModel bar) async {
    throw UnimplementedError('Use createBarWithReservation() para operações atômicas.');
  }

  @override
  Future<String> createBarWithReservation({
    required BarModel bar,
    required String ownerUid,
    String? forcedBarId,
  }) async {
    debugPrint('🏢 [FirebaseBarRepository] Iniciando createBarWithReservation...');
    debugPrint('🏢 [FirebaseBarRepository] CNPJ: ${bar.cnpj.substring(0, 3)}***, Nome: ${bar.name}, Owner: $ownerUid');
    
    final normalizedCnpj = _normalizeCnpj(bar.cnpj);
    final barId = forcedBarId ?? _barsCol.doc().id;
    
    debugPrint('🏢 [FirebaseBarRepository] CNPJ normalizado: $normalizedCnpj, BarId: $barId');

    final batch = _firestore.batch();

    final cnpjRef = _cnpjRegCol.doc(normalizedCnpj);
    final barRef = _barsCol.doc(barId);
    final memberRef = barRef.collection(FirestoreKeys.membersSubcollection).doc(ownerUid);

    // 1) Reserva CNPJ
    debugPrint('🏢 [FirebaseBarRepository] Adicionando reserva de CNPJ ao batch...');
    batch.set(cnpjRef, {
      'barId': barId,
      'reservedByUid': ownerUid,
      'createdAt': _now,
    });

    // 2) Cria o bar
    debugPrint('🏢 [FirebaseBarRepository] Preparando dados do bar...');
    final barWithIds = bar.copyWith(
      id: barId,
      cnpj: normalizedCnpj,
      createdAt: DateTime.now(), // será sobrescrito pelo _now
      updatedAt: DateTime.now(), // será sobrescrito pelo _now
      createdByUid: ownerUid,
      primaryOwnerUid: ownerUid, // Campo obrigatório para validação do Firestore
    );
    final barData = _toFirestore(barWithIds)
      ..addAll({
        'createdAt': _now,
        'updatedAt': _now,
        'createdByUid': ownerUid,
        'primaryOwnerUid': ownerUid, // Campo obrigatório para validação do Firestore
      });

    debugPrint('🏢 [FirebaseBarRepository] Adicionando bar ao batch...');
    batch.set(barRef, barData);

    // 3) Adiciona o criador como membro OWNER
    debugPrint('🏢 [FirebaseBarRepository] Adicionando membership OWNER ao batch...');
    batch.set(memberRef, {
      'uid': ownerUid,
      'role': 'OWNER',
      'createdAt': _now,
      'barId': barId,
      'barName': bar.name,
    });

    debugPrint('🏢 [FirebaseBarRepository] Executando batch commit...');
    await batch.commit();
    debugPrint('✅ [FirebaseBarRepository] Bar criado com sucesso! BarId: $barId');
    return barId;
  }

  @override
  Future<void> update(BarModel bar) async {
    debugPrint('📝 [FirebaseBarRepository] Iniciando update do bar: ${bar.id}');
    debugPrint('📝 [FirebaseBarRepository] Nome: ${bar.name}, CNPJ: ${bar.cnpj.substring(0, 3)}***');
    try {
      debugPrint('📝 [FirebaseBarRepository] Atualizando documento no Firestore...');
      await _barsCol.doc(bar.id).update(
        _toFirestore(bar)..addAll({'updatedAt': _now}),
      );
      debugPrint('✅ [FirebaseBarRepository] Bar atualizado com sucesso!');
    } catch (e) {
      debugPrint('❌ [FirebaseBarRepository] Erro ao atualizar bar: $e');
      throw Exception('Erro ao atualizar informações do bar. Tente novamente.');
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
  Future<List<BarModel>> getUserBars(String uid) async {
    debugPrint('👥 [FirebaseBarRepository] Buscando bares do usuário: $uid');
    try {
      debugPrint('👥 [FirebaseBarRepository] Consultando collection group members...');
      final querySnapshot = await _firestore
          .collectionGroup(FirestoreKeys.membersSubcollection)
          .where('uid', isEqualTo: uid)
          .get();

      debugPrint('👥 [FirebaseBarRepository] Encontrados ${querySnapshot.docs.length} memberships');
      final List<BarModel> bars = [];
      for (final memberDoc in querySnapshot.docs) {
        final barId = memberDoc.data()['barId'] as String?;
        debugPrint('👥 [FirebaseBarRepository] Processando membership para barId: $barId');
        if (barId != null) {
          final bar = await getById(barId);
          if (bar != null) {
            debugPrint('👥 [FirebaseBarRepository] Bar adicionado à lista: ${bar.name}');
            bars.add(bar);
          } else {
            debugPrint('⚠️ [FirebaseBarRepository] Bar não encontrado para barId: $barId');
          }
        }
      }

      debugPrint('✅ [FirebaseBarRepository] Total de bares encontrados: ${bars.length}');
      return bars;
    } catch (e) {
      debugPrint('❌ [FirebaseBarRepository] Erro ao buscar bares do usuário: $e');
      throw Exception('Erro ao carregar seus bares. Tente novamente.');
    }
  }

  @override
  Future<void> addMember(String barId, String uid, String role) async {
    debugPrint('👤 [FirebaseBarRepository] Adicionando membro: uid=$uid, barId=$barId, role=$role');
    try {
      final barRef = _barsCol.doc(barId);
      final memberRef = barRef.collection(FirestoreKeys.membersSubcollection).doc(uid);
      
      // Busca o nome do bar para desnormalizar
      debugPrint('👤 [FirebaseBarRepository] Buscando dados do bar para desnormalização...');
      final barDoc = await barRef.get();
      final barData = barDoc.data();
      final barName = barDoc.exists && barData != null ? barData['name'] ?? '' : '';
      
      if (!barDoc.exists) {
        debugPrint('❌ [FirebaseBarRepository] Bar não encontrado: $barId');
        throw Exception('Bar não encontrado');
      }
      
      debugPrint('👤 [FirebaseBarRepository] Criando documento de membership...');
      await memberRef.set({
        'uid': uid,
        'role': role,
        'createdAt': _now,
        'barId': barId,
        'barName': barName,
      });
      debugPrint('✅ [FirebaseBarRepository] Membro adicionado com sucesso!');
    } catch (e) {
      debugPrint('❌ [FirebaseBarRepository] Erro ao adicionar membro: $e');
      throw Exception('Erro ao adicionar membro. Tente novamente.');
    }
  }

  Future<BarModel?> getById(String barId) async {
    debugPrint('🔍 [FirebaseBarRepository] Buscando bar por ID: $barId');
    try {
      final doc = await _barsCol.doc(barId).get();
      if (!doc.exists) {
        debugPrint('🔍 [FirebaseBarRepository] Bar não encontrado: $barId');
        return null;
      }
      debugPrint('✅ [FirebaseBarRepository] Bar encontrado: $barId');
      return _fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ [FirebaseBarRepository] Erro ao buscar bar: $e');
      throw Exception('Erro ao carregar informações do bar. Tente novamente.');
    }
  }

  @override
  Future<bool> isCnpjInUse(String cnpj) async {
    try {
      debugPrint('🔍 [FirebaseBarRepository] Verificando se CNPJ está em uso: ${cnpj.substring(0, 3)}***');
      final normalizedCnpj = _normalizeCnpj(cnpj);
      debugPrint('🔍 [FirebaseBarRepository] CNPJ normalizado: $normalizedCnpj');
      debugPrint('🔍 [FirebaseBarRepository] Consultando documento: ${FirestoreKeys.cnpjRegistryCollection}/$normalizedCnpj');
      
      final doc = await _cnpjRegCol.doc(normalizedCnpj).get();
      final exists = doc.exists;
      debugPrint('🔍 [FirebaseBarRepository] CNPJ em uso: $exists');
      
      if (doc.exists) {
        final data = doc.data();
        debugPrint('🔍 [FirebaseBarRepository] Dados do documento: $data');
      }
      
      return exists;
    } catch (e) {
      debugPrint('❌ [FirebaseBarRepository] Erro ao verificar CNPJ: $e');
      throw Exception('Erro ao verificar CNPJ. Tente novamente.');
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

  Future<void> removeMember(String barId, String uid) async {
    debugPrint('🗑️ [FirebaseBarRepository] Removendo membro: uid=$uid, barId=$barId');
    try {
      debugPrint('🗑️ [FirebaseBarRepository] Deletando documento de membership...');
      await _barsCol
          .doc(barId)
          .collection(FirestoreKeys.membersSubcollection)
          .doc(uid)
          .delete();
      debugPrint('✅ [FirebaseBarRepository] Membro removido com sucesso!');
    } catch (e) {
      debugPrint('❌ [FirebaseBarRepository] Erro ao remover membro: $e');
      throw Exception('Erro ao remover membro. Tente novamente.');
    }
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