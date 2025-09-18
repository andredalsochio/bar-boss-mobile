import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository_domain.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';
import 'package:bar_boss_mobile/app/core/schema/firestore_keys.dart';
import 'package:bar_boss_mobile/app/core/utils/normalization_helpers.dart';

/// Implementação Firebase da interface BarRepositoryDomain
class FirebaseBarRepository implements BarRepositoryDomain {
  final FirebaseFirestore _firestore;
  
  FirebaseBarRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _barsCol =>
      _firestore.collection(FirestoreKeys.barsCollection);

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
    required String primaryOwnerUid,
    String? forcedBarId,
  }) async {
    debugPrint('🏢 [FirebaseBarRepository] Iniciando createBarWithReservation...');
    debugPrint('🏢 [FirebaseBarRepository] CNPJ: ${bar.cnpj.substring(0, 3)}***, Nome: ${bar.name}, Owner: $primaryOwnerUid');
    
    // 🔍 DEBUG: Verificar estado da autenticação Firebase
    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('🔍 [FirebaseBarRepository] Estado da autenticação:');
    debugPrint('🔍 [FirebaseBarRepository] - currentUser: ${currentUser?.uid}');
    debugPrint('🔍 [FirebaseBarRepository] - primaryOwnerUid: $primaryOwnerUid');
    debugPrint('🔍 [FirebaseBarRepository] - UIDs iguais: ${currentUser?.uid == primaryOwnerUid}');
    debugPrint('🔍 [FirebaseBarRepository] - emailVerified: ${currentUser?.emailVerified}');
    debugPrint('🔍 [FirebaseBarRepository] - isAnonymous: ${currentUser?.isAnonymous}');
    debugPrint('🔍 [FirebaseBarRepository] - providerData: ${currentUser?.providerData.map((p) => p.providerId).toList()}');
    
    final normalizedCnpj = _normalizeCnpj(bar.cnpj);
    // Usar CNPJ normalizado como docId para garantir unicidade
    final barId = forcedBarId ?? normalizedCnpj;
    
    debugPrint('🏢 [FirebaseBarRepository] CNPJ normalizado: $normalizedCnpj, BarId (usando CNPJ): $barId');

    final batch = _firestore.batch();

    final barRef = _barsCol.doc(barId);
    final memberRef = barRef.collection(FirestoreKeys.membersSubcollection).doc(primaryOwnerUid);
    final cnpjRegistryRef = _firestore.collection('cnpj_registry').doc(normalizedCnpj);

    // 1) Cria o registro no cnpj_registry (para garantir unicidade)
    debugPrint('🏢 [FirebaseBarRepository] Adicionando cnpj_registry ao batch...');
    batch.set(cnpjRegistryRef, {
      'cnpj': normalizedCnpj,
      'primaryOwnerUid': primaryOwnerUid,
      'createdAt': _now,
    });

    // 2) Cria o bar
    debugPrint('🏢 [FirebaseBarRepository] Preparando dados do bar...');
    final barWithIds = bar.copyWith(
      id: barId,
      cnpj: normalizedCnpj,
      createdAt: DateTime.now(), // será sobrescrito pelo _now
      updatedAt: DateTime.now(), // será sobrescrito pelo _now
      createdByUid: primaryOwnerUid,
      primaryOwnerUid: primaryOwnerUid, // Campo obrigatório para validação do Firestore
    );
    final barData = _toFirestore(barWithIds)
      ..addAll({
        'createdAt': _now,
        'updatedAt': _now,
        'createdByUid': primaryOwnerUid,
        'primaryOwnerUid': primaryOwnerUid, // Campo obrigatório para validação do Firestore
      });

    debugPrint('🏢 [FirebaseBarRepository] Adicionando bar ao batch...');
    batch.set(barRef, barData);

    // 3) Adiciona o criador como membro OWNER
    debugPrint('🏢 [FirebaseBarRepository] Adicionando membership OWNER ao batch...');
    batch.set(memberRef, {
      'uid': primaryOwnerUid,
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

  /// Método simples para criar bar sem batch complexo
  /// Usado especialmente para fluxo social
  Future<void> createBarSimple(BarModel bar) async {
    final cnpjLimpo = NormalizationHelpers.normalizeCnpj(bar.cnpj);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    if (uid == null) {
      debugPrint('❌ [FirebaseBarRepository] Usuário não autenticado');
      throw Exception('Usuário não autenticado');
    }

    debugPrint('🏗️ [FirebaseBarRepository] Criando bar simples: $cnpjLimpo');
    debugPrint('🏗️ [FirebaseBarRepository] Nome: ${bar.name}, Owner: $uid');
    
    try {
      // Usar batch para garantir atomicidade das 3 escritas
      final batch = _firestore.batch();
      
      // 1. Criar documento do bar
      final barData = _toFirestore(bar)..addAll({
        'createdAt': _now,
        'updatedAt': _now,
        'primaryOwnerUid': uid, // Campo necessário para as rules
      });
      
      debugPrint('🏗️ [FirebaseBarRepository] Dados do bar: ${barData.keys.toList()}');
      debugPrint('🏗️ [FirebaseBarRepository] Criando documento bars/$cnpjLimpo...');
      
      batch.set(_barsCol.doc(cnpjLimpo), barData);
      
      // 2. Criar membership do owner
      debugPrint('🏗️ [FirebaseBarRepository] Criando membership do owner...');
      final memberData = {
        'uid': uid,
        'role': 'OWNER',
        'createdAt': _now,
        'barId': cnpjLimpo,
        'barName': bar.name,
      };
      
      debugPrint('🏗️ [FirebaseBarRepository] Dados do member: ${memberData.keys.toList()}');
      batch.set(
        _barsCol
            .doc(cnpjLimpo)
            .collection(FirestoreKeys.membersSubcollection)
            .doc(uid),
        memberData,
      );
      
      // 3. Criar registro no cnpj_registry
       debugPrint('🏗️ [FirebaseBarRepository] Criando registro no cnpj_registry...');
       final cnpjRegistryData = {
         'cnpj': cnpjLimpo,
         'primaryOwnerUid': uid,
         'barId': cnpjLimpo,
         'contactEmail': bar.contactEmail.toLowerCase().trim(),
         'createdAt': _now,
         'createdByUid': uid,
       };
      
      debugPrint('🏗️ [FirebaseBarRepository] Dados do cnpj_registry: ${cnpjRegistryData.keys.toList()}');
      batch.set(
        _firestore.collection('cnpj_registry').doc(cnpjLimpo),
        cnpjRegistryData,
      );
      
      // Executar todas as operações atomicamente
      await batch.commit();
      
      debugPrint('✅ [FirebaseBarRepository] Bar criado com sucesso!');
      debugPrint('✅ [FirebaseBarRepository] Membership criado com sucesso!');
      debugPrint('✅ [FirebaseBarRepository] CNPJ registrado com sucesso!');
      debugPrint('✅ [FirebaseBarRepository] Bar simples criado com sucesso!');
    } catch (e, stackTrace) {
      debugPrint('❌ [FirebaseBarRepository] Erro ao criar bar simples: $e');
      debugPrint('❌ [FirebaseBarRepository] Stack trace: $stackTrace');
      throw Exception('Erro ao criar bar. Tente novamente.');
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

      debugPrint('👥 [FirebaseBarRepository] Encontrados ${querySnapshot.docs.length} members');
      final List<BarModel> bars = [];
      for (final memberDoc in querySnapshot.docs) {
        final barId = memberDoc.data()['barId'] as String?;
        debugPrint('👥 [FirebaseBarRepository] Processando member para barId: $barId');
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
      // Não incluir createdAt, updatedAt e primaryOwnerUid aqui
      // pois são adicionados separadamente no createBarSimple
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

  @override
  Future<bool> isEmailUnique(String email) async {
    try {
      final normalizedEmail = NormalizationHelpers.normalizeEmail(email);
      final query = await _barsCol
          .where('contactEmail', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      
      return query.docs.isEmpty;
    } catch (e) {
      debugPrint('❌ [FirebaseBarRepository] Erro ao verificar unicidade do email: $e');
      throw Exception('Erro ao verificar email. Tente novamente.');
    }
  }

  @override
  Future<bool> isCnpjUnique(String cnpj) async {
    try {
      final normalizedCnpj = NormalizationHelpers.normalizeCnpj(cnpj);
      final query = await _barsCol
          .where('cnpj', isEqualTo: normalizedCnpj)
          .limit(1)
          .get();
      
      return query.docs.isEmpty;
    } catch (e) {
      debugPrint('❌ [FirebaseBarRepository] Erro ao verificar unicidade do CNPJ: $e');
      throw Exception('Erro ao verificar CNPJ. Tente novamente.');
    }
  }

  @override
  Future<bool> checkCnpjExists(String cnpjClean) async {
    debugPrint('🔍 [FirebaseBarRepository] Verificando existência do CNPJ: ${cnpjClean.substring(0, 4)}***');
    try {
      // Verificar APENAS no cnpj_registry (conforme regras do Firestore)
      debugPrint('🔍 [FirebaseBarRepository] Consultando cnpj_registry...');
      final cnpjRegistryDoc = await _firestore
          .collection('cnpj_registry')
          .doc(cnpjClean)
          .get();
      
      final exists = cnpjRegistryDoc.exists;
      debugPrint('✅ [FirebaseBarRepository] CNPJ existe: $exists');
      return exists;
    } catch (e) {
      debugPrint('❌ [FirebaseBarRepository] Erro ao verificar existência do CNPJ: $e');
      throw Exception('Erro ao verificar CNPJ. Tente novamente.');
    }
  }

  @override
  Future<void> ensureMembership(String barId, String uid) async {
    debugPrint('🔗 [FirebaseBarRepository] Garantindo membership para barId: $barId, uid: $uid');
    
    try {
      final memberRef = _barsCol.doc(barId).collection(FirestoreKeys.membersSubcollection).doc(uid);
      final memberDoc = await memberRef.get();
      
      if (!memberDoc.exists) {
        debugPrint('🔗 [FirebaseBarRepository] Membership não existe, criando...');
        
        // Buscar dados do bar para o membership
        final barDoc = await _barsCol.doc(barId).get();
        final barName = barDoc.exists ? (barDoc.data()?['name'] ?? 'Bar') : 'Bar';
        
        await memberRef.set({
          'uid': uid,
          'role': 'OWNER',
          'createdAt': _now,
          'barId': barId,
          'barName': barName,
        });
        
        debugPrint('✅ [FirebaseBarRepository] Membership criado com sucesso');
      } else {
        debugPrint('✅ [FirebaseBarRepository] Membership já existe');
      }
    } catch (e) {
      debugPrint('❌ [FirebaseBarRepository] Erro ao garantir membership: $e');
      throw Exception('Erro ao garantir acesso ao bar. Tente novamente.');
    }
  }

  @override
  Future<List<BarModel>> getBarsByOwner(String primaryOwnerUid) async {
    try {
      debugPrint('🔍 [FirebaseBarRepository] Buscando bares do proprietário: $primaryOwnerUid');
      
      final querySnapshot = await _firestore
          .collection(FirestoreKeys.barsCollection)
          .where(FirestoreKeys.barPrimaryOwnerUid, isEqualTo: primaryOwnerUid)
          .get();

      final bars = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return BarModel.fromMap(data, doc.id);
      }).toList();

      debugPrint('✅ [FirebaseBarRepository] Encontrados ${bars.length} bares');
      return bars;
    } catch (e) {
      debugPrint('❌ [FirebaseBarRepository] Erro ao buscar bares: $e');
      rethrow;
    }
  }

  @override
  Stream<List<BarModel>> getBarsStream(String primaryOwnerUid) {
    try {
      debugPrint('🔄 [FirebaseBarRepository] Iniciando stream de bares para: $primaryOwnerUid');
      
      return _firestore
          .collection(FirestoreKeys.barsCollection)
          .where(FirestoreKeys.barPrimaryOwnerUid, isEqualTo: primaryOwnerUid)
          .snapshots()
          .map((snapshot) {
        final bars = snapshot.docs.map((doc) {
          final data = doc.data();
          return BarModel.fromMap(data, doc.id);
        }).toList();

        debugPrint('🔄 [FirebaseBarRepository] Stream atualizado: ${bars.length} bares');
        return bars;
      });
    } catch (e) {
      debugPrint('❌ [FirebaseBarRepository] Erro no stream de bares: $e');
      rethrow;
    }
  }
}