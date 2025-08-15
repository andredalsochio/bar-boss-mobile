import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Classe responsável por gerenciar o armazenamento local de rascunhos do cadastro
class DraftStorage {
  static const String _step1Key = 'bar_registration_step1_draft';
  static const String _step2Key = 'bar_registration_step2_draft';
  
  /// Salva o rascunho do Passo 1 (Informações de Contato)
  static Future<void> saveStep1Draft({
    required String email,
    required String cnpj,
    required String name,
    required String responsibleName,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final step1Data = {
      'email': email,
      'cnpj': cnpj,
      'name': name,
      'responsibleName': responsibleName,
      'phone': phone,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_step1Key, jsonEncode(step1Data));
  }
  
  /// Salva o rascunho do Passo 2 (Endereço)
  static Future<void> saveStep2Draft({
    required String cep,
    required String street,
    required String number,
    required String complement,
    required String state,
    required String city,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final step2Data = {
      'cep': cep,
      'street': street,
      'number': number,
      'complement': complement,
      'state': state,
      'city': city,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_step2Key, jsonEncode(step2Data));
  }
  
  /// Lê o rascunho do Passo 1
  static Future<Map<String, String>?> readStep1Draft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString(_step1Key);
    
    if (draftJson == null) return null;
    
    try {
      final Map<String, dynamic> draftData = jsonDecode(draftJson);
      return {
        'email': draftData['email'] ?? '',
        'cnpj': draftData['cnpj'] ?? '',
        'name': draftData['name'] ?? '',
        'responsibleName': draftData['responsibleName'] ?? '',
        'phone': draftData['phone'] ?? '',
      };
    } catch (e) {
      // Se houver erro na deserialização, remove o rascunho corrompido
      await prefs.remove(_step1Key);
      return null;
    }
  }
  
  /// Lê o rascunho do Passo 2
  static Future<Map<String, String>?> readStep2Draft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString(_step2Key);
    
    if (draftJson == null) return null;
    
    try {
      final Map<String, dynamic> draftData = jsonDecode(draftJson);
      return {
        'cep': draftData['cep'] ?? '',
        'street': draftData['street'] ?? '',
        'number': draftData['number'] ?? '',
        'complement': draftData['complement'] ?? '',
        'state': draftData['state'] ?? '',
        'city': draftData['city'] ?? '',
      };
    } catch (e) {
      // Se houver erro na deserialização, remove o rascunho corrompido
      await prefs.remove(_step2Key);
      return null;
    }
  }
  
  /// Limpa todos os rascunhos (chamado após conclusão do cadastro)
  static Future<void> clearAllDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_step1Key),
      prefs.remove(_step2Key),
    ]);
  }
  
  /// Verifica se existe rascunho do Passo 1
  static Future<bool> hasStep1Draft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_step1Key);
  }
  
  /// Verifica se existe rascunho do Passo 2
  static Future<bool> hasStep2Draft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_step2Key);
  }
  
  /// Limpa apenas o rascunho do Passo 1
  static Future<void> clearStep1Draft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_step1Key);
  }
  
  /// Limpa apenas o rascunho do Passo 2
  static Future<void> clearStep2Draft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_step2Key);
  }
}

// OPÇÃO B - REMOTO (Esqueleto para futura implementação)
// TODO: Implementar sincronização remota de rascunhos

/// Classe para gerenciar rascunhos remotos no Firestore (futura implementação)
class RemoteDraftStorage {
  // TODO: Implementar métodos para sincronização remota
  
  /// Salva rascunho remoto no Firestore com status "draft"
  /// Documento: /bars/{tempId} com status: "draft"
  static Future<void> saveRemoteDraft({
    required String tempId,
    required Map<String, dynamic> draftData,
  }) async {
    // TODO: Implementar salvamento no Firestore
    // - Criar documento temporário em /bars/{tempId}
    // - Adicionar campo status: "draft"
    // - Incluir timestamp de última modificação
    // - Implementar merge de dados entre passos
    throw UnimplementedError('Implementação futura');
  }
  
  /// Lê rascunho remoto do Firestore
  static Future<Map<String, dynamic>?> readRemoteDraft(String tempId) async {
    // TODO: Implementar leitura do Firestore
    // - Buscar documento /bars/{tempId}
    // - Verificar se status == "draft"
    // - Retornar dados ou null se não existir
    throw UnimplementedError('Implementação futura');
  }
  
  /// Converte rascunho para documento final e remove status "draft"
  static Future<void> promoteDraftToFinal(String tempId) async {
    // TODO: Implementar promoção de rascunho
    // - Remover campo status: "draft"
    // - Adicionar campos de documento final
    // - Validar integridade dos dados
    throw UnimplementedError('Implementação futura');
  }
  
  /// Remove rascunho remoto
  static Future<void> clearRemoteDraft(String tempId) async {
    // TODO: Implementar remoção do Firestore
    // - Deletar documento /bars/{tempId} se status == "draft"
    throw UnimplementedError('Implementação futura');
  }
  
  /// Sincroniza rascunho local com remoto
  static Future<void> syncDrafts(String tempId) async {
    // TODO: Implementar sincronização bidirecional
    // - Comparar timestamps local vs remoto
    // - Fazer merge inteligente dos dados
    // - Resolver conflitos de sincronização
    throw UnimplementedError('Implementação futura');
  }
}