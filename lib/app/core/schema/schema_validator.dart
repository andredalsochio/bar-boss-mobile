import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_keys.dart';

/// Validador de schemas para debug que verifica se os documentos
/// lidos do Firestore estão em conformidade com os schemas definidos
class SchemaValidator {
  static const String _tag = 'SchemaValidator';
  
  /// Configuração para aplicar defaults automaticamente
  static bool autoApplyDefaults = false;
  
  /// Configuração para fazer update automático uma vez
  static bool autoUpdateOnce = false;
  
  /// Cache de documentos já atualizados para evitar loops
  static final Set<String> _updatedDocs = <String>{};

  /// Valida um documento de usuário
  static void validateUser(String uid, Map<String, dynamic>? data) {
    if (!kDebugMode) return;
    
    if (data == null) {
      _logError('User document $uid is null');
      return;
    }

    final issues = <String>[];
    final missing = <String>[];
    final unknown = <String>[];
    
    // Campos obrigatórios
    final requiredFields = {
      FirestoreKeys.userEmail: 'String',
      FirestoreKeys.userDisplayName: 'String',
      FirestoreKeys.userCreatedAt: 'Timestamp',
    };
    
    // Campos opcionais
    final optionalFields = {
      FirestoreKeys.userPhotoUrl: 'String',
      FirestoreKeys.userProviders: 'List<String>',
      FirestoreKeys.userCurrentBarId: 'String',
      FirestoreKeys.userLastLoginAt: 'Timestamp',
    };
    
    // Verificar campos obrigatórios
    for (final entry in requiredFields.entries) {
      if (!data.containsKey(entry.key)) {
        missing.add('${entry.key} (${entry.value})');
      } else if (!_isValidType(data[entry.key], entry.value)) {
        issues.add('${entry.key}: expected ${entry.value}, got ${data[entry.key].runtimeType}');
      }
    }
    
    // Verificar campos opcionais
    for (final entry in optionalFields.entries) {
      if (data.containsKey(entry.key) && data[entry.key] != null) {
        if (!_isValidType(data[entry.key], entry.value)) {
          issues.add('${entry.key}: expected ${entry.value}, got ${data[entry.key].runtimeType}');
        }
      }
    }
    
    // Verificar campos desconhecidos
    final allKnownFields = {...requiredFields.keys, ...optionalFields.keys};
    for (final key in data.keys) {
      if (!allKnownFields.contains(key)) {
        unknown.add(key);
      }
    }
    
    _logValidationResult('User', uid, issues, missing, unknown);
    
    if (autoApplyDefaults || autoUpdateOnce) {
      _applyUserDefaults(uid, data, missing);
    }
  }

  /// Valida um documento de bar
  static void validateBar(String barId, Map<String, dynamic>? data) {
    if (!kDebugMode) return;
    
    if (data == null) {
      _logError('Bar document $barId is null');
      return;
    }

    final issues = <String>[];
    final missing = <String>[];
    final unknown = <String>[];
    
    // Campos obrigatórios
    final requiredFields = {
      FirestoreKeys.barName: 'String',
      FirestoreKeys.barCnpj: 'String',
      FirestoreKeys.barResponsibleName: 'String',
      FirestoreKeys.barContactEmail: 'String',
      FirestoreKeys.barContactPhone: 'String',
      FirestoreKeys.barAddress: 'Map',
      FirestoreKeys.barCreatedAt: 'Timestamp',
      FirestoreKeys.barCreatedByUid: 'String',
      FirestoreKeys.barPrimaryOwnerUid: 'String',
    };
    
    // Campos opcionais
    final optionalFields = {
      FirestoreKeys.barProfile: 'Map',
      FirestoreKeys.barStatus: 'String',
      FirestoreKeys.barLogoUrl: 'String',
      FirestoreKeys.barUpdatedAt: 'Timestamp',
    };
    
    // Verificar campos obrigatórios
    for (final entry in requiredFields.entries) {
      if (!data.containsKey(entry.key)) {
        missing.add('${entry.key} (${entry.value})');
      } else if (!_isValidType(data[entry.key], entry.value)) {
        issues.add('${entry.key}: expected ${entry.value}, got ${data[entry.key].runtimeType}');
      }
    }
    
    // Verificar campos opcionais
    for (final entry in optionalFields.entries) {
      if (data.containsKey(entry.key) && data[entry.key] != null) {
        if (!_isValidType(data[entry.key], entry.value)) {
          issues.add('${entry.key}: expected ${entry.value}, got ${data[entry.key].runtimeType}');
        }
      }
    }
    
    // Validar nested objects
    if (data.containsKey(FirestoreKeys.barAddress)) {
      _validateAddress(data[FirestoreKeys.barAddress], issues, missing);
    }
    
    if (data.containsKey(FirestoreKeys.barProfile)) {
      _validateBarProfile(data[FirestoreKeys.barProfile], issues, missing);
    }
    
    // Verificar campos desconhecidos
    final allKnownFields = {...requiredFields.keys, ...optionalFields.keys};
    for (final key in data.keys) {
      if (!allKnownFields.contains(key)) {
        unknown.add(key);
      }
    }
    
    _logValidationResult('Bar', barId, issues, missing, unknown);
    
    if (autoApplyDefaults || autoUpdateOnce) {
      _applyBarDefaults(barId, data, missing);
    }
  }

  /// Valida um documento de evento
  static void validateEvent(String barId, String eventId, Map<String, dynamic>? data) {
    if (!kDebugMode) return;
    
    if (data == null) {
      _logError('Event document $barId/$eventId is null');
      return;
    }

    final issues = <String>[];
    final missing = <String>[];
    final unknown = <String>[];
    
    // Campos obrigatórios
    final requiredFields = {
      FirestoreKeys.eventBarId: 'String',
      FirestoreKeys.eventTitle: 'String',
      FirestoreKeys.eventStartAt: 'Timestamp',
      FirestoreKeys.eventCreatedAt: 'Timestamp',
      FirestoreKeys.eventCreatedByUid: 'String',
    };
    
    // Campos opcionais
    final optionalFields = {
      FirestoreKeys.eventEndAt: 'Timestamp',
      FirestoreKeys.eventDescription: 'String',
      FirestoreKeys.eventAttractions: 'List<String>',
      FirestoreKeys.eventCoverImageUrl: 'String',
      FirestoreKeys.eventPublished: 'bool',
      FirestoreKeys.eventUpdatedAt: 'Timestamp',
      FirestoreKeys.eventUpdatedByUid: 'String',
    };
    
    // Verificar campos obrigatórios
    for (final entry in requiredFields.entries) {
      if (!data.containsKey(entry.key)) {
        missing.add('${entry.key} (${entry.value})');
      } else if (!_isValidType(data[entry.key], entry.value)) {
        issues.add('${entry.key}: expected ${entry.value}, got ${data[entry.key].runtimeType}');
      }
    }
    
    // Verificar campos opcionais
    for (final entry in optionalFields.entries) {
      if (data.containsKey(entry.key) && data[entry.key] != null) {
        if (!_isValidType(data[entry.key], entry.value)) {
          issues.add('${entry.key}: expected ${entry.value}, got ${data[entry.key].runtimeType}');
        }
      }
    }
    
    // Validação específica: endAt >= startAt
    if (data.containsKey(FirestoreKeys.eventStartAt) && 
        data.containsKey(FirestoreKeys.eventEndAt) &&
        data[FirestoreKeys.eventEndAt] != null) {
      final startAt = data[FirestoreKeys.eventStartAt];
      final endAt = data[FirestoreKeys.eventEndAt];
      
      if (startAt is Timestamp && endAt is Timestamp) {
        if (endAt.toDate().isBefore(startAt.toDate())) {
          issues.add('endAt must be >= startAt');
        }
      }
    }
    
    // Verificar campos desconhecidos
    final allKnownFields = {...requiredFields.keys, ...optionalFields.keys};
    for (final key in data.keys) {
      if (!allKnownFields.contains(key)) {
        unknown.add(key);
      }
    }
    
    _logValidationResult('Event', '$barId/$eventId', issues, missing, unknown);
    
    if (autoApplyDefaults || autoUpdateOnce) {
      _applyEventDefaults(barId, eventId, data, missing);
    }
  }

  /// Valida um documento de membro
  static void validateMember(String barId, String uid, Map<String, dynamic>? data) {
    if (!kDebugMode) return;
    
    if (data == null) {
      _logError('Member document $barId/$uid is null');
      return;
    }

    final issues = <String>[];
    final missing = <String>[];
    final unknown = <String>[];
    
    // Campos obrigatórios
    final requiredFields = {
      FirestoreKeys.memberUid: 'String',
      FirestoreKeys.memberRole: 'String',
      FirestoreKeys.memberCreatedAt: 'Timestamp',
    };
    
    // Campos opcionais
    final optionalFields = {
      FirestoreKeys.memberInvitedByUid: 'String',
    };
    
    // Verificar campos obrigatórios
    for (final entry in requiredFields.entries) {
      if (!data.containsKey(entry.key)) {
        missing.add('${entry.key} (${entry.value})');
      } else if (!_isValidType(data[entry.key], entry.value)) {
        issues.add('${entry.key}: expected ${entry.value}, got ${data[entry.key].runtimeType}');
      }
    }
    
    // Verificar role válido
    if (data.containsKey(FirestoreKeys.memberRole)) {
      final role = data[FirestoreKeys.memberRole];
      final validRoles = [FirestoreKeys.roleOwner, FirestoreKeys.roleAdmin, FirestoreKeys.roleEditor];
      if (!validRoles.contains(role)) {
        issues.add('role: invalid value "$role", must be one of $validRoles');
      }
    }
    
    // Verificar campos opcionais
    for (final entry in optionalFields.entries) {
      if (data.containsKey(entry.key) && data[entry.key] != null) {
        if (!_isValidType(data[entry.key], entry.value)) {
          issues.add('${entry.key}: expected ${entry.value}, got ${data[entry.key].runtimeType}');
        }
      }
    }
    
    // Verificar campos desconhecidos
    final allKnownFields = {...requiredFields.keys, ...optionalFields.keys};
    for (final key in data.keys) {
      if (!allKnownFields.contains(key)) {
        unknown.add(key);
      }
    }
    
    _logValidationResult('Member', '$barId/$uid', issues, missing, unknown);
  }

  // Métodos auxiliares privados
  
  static bool _isValidType(dynamic value, String expectedType) {
    switch (expectedType) {
      case 'String':
        return value is String;
      case 'bool':
        return value is bool;
      case 'int':
        return value is int;
      case 'double':
        return value is double;
      case 'List<String>':
        return value is List && value.every((e) => e is String);
      case 'Map':
        return value is Map;
      case 'Timestamp':
        return value is Timestamp;
      default:
        return true; // Tipo desconhecido, assumir válido
    }
  }
  
  static void _validateAddress(dynamic address, List<String> issues, List<String> missing) {
    if (address is! Map) {
      issues.add('address: expected Map, got ${address.runtimeType}');
      return;
    }
    
    final addressMap = address as Map<String, dynamic>;
    final requiredAddressFields = {
      FirestoreKeys.addressCep: 'String',
      FirestoreKeys.addressStreet: 'String',
      FirestoreKeys.addressNumber: 'String',
      FirestoreKeys.addressState: 'String',
      FirestoreKeys.addressCity: 'String',
    };
    
    for (final entry in requiredAddressFields.entries) {
      if (!addressMap.containsKey(entry.key)) {
        missing.add('address.${entry.key} (${entry.value})');
      } else if (!_isValidType(addressMap[entry.key], entry.value)) {
        issues.add('address.${entry.key}: expected ${entry.value}, got ${addressMap[entry.key].runtimeType}');
      }
    }
  }
  
  static void _validateBarProfile(dynamic profile, List<String> issues, List<String> missing) {
    if (profile is! Map) {
      issues.add('profile: expected Map, got ${profile.runtimeType}');
      return;
    }
    
    final profileMap = profile as Map<String, dynamic>;
    final profileFields = {
      FirestoreKeys.profileContactsComplete: 'bool',
      FirestoreKeys.profileAddressComplete: 'bool',
    };
    
    for (final entry in profileFields.entries) {
      if (profileMap.containsKey(entry.key) && profileMap[entry.key] != null) {
        if (!_isValidType(profileMap[entry.key], entry.value)) {
          issues.add('profile.${entry.key}: expected ${entry.value}, got ${profileMap[entry.key].runtimeType}');
        }
      }
    }
  }
  
  static void _logValidationResult(String docType, String docId, 
      List<String> issues, List<String> missing, List<String> unknown) {
    
    if (issues.isEmpty && missing.isEmpty && unknown.isEmpty) {
      return; // Documento válido, não logar
    }
    
    final buffer = StringBuffer();
    buffer.writeln('[$_tag] $docType validation issues for $docId:');
    
    if (missing.isNotEmpty) {
      buffer.writeln('  Missing fields: ${missing.join(", ")}');
    }
    
    if (issues.isNotEmpty) {
      buffer.writeln('  Type/validation issues: ${issues.join(", ")}');
    }
    
    if (unknown.isNotEmpty) {
      buffer.writeln('  Unknown fields: ${unknown.join(", ")}');
    }
    
    developer.log(buffer.toString(), name: _tag);
  }
  
  static void _logError(String message) {
    developer.log('[$_tag] ERROR: $message', name: _tag);
  }
  
  // Métodos para aplicar defaults (implementação básica)
  
  static void _applyUserDefaults(String uid, Map<String, dynamic> data, List<String> missing) {
    if (!autoApplyDefaults && !autoUpdateOnce) return;
    
    final docKey = 'users/$uid';
    if (autoUpdateOnce && _updatedDocs.contains(docKey)) return;
    
    final updates = <String, dynamic>{};
    
    // Aplicar defaults para campos missing
    for (final field in missing) {
      if (field.startsWith(FirestoreKeys.userProviders)) {
        updates[FirestoreKeys.userProviders] = <String>[];
      }
    }
    
    if (updates.isNotEmpty) {
      _performUpdate('users', uid, updates);
      if (autoUpdateOnce) _updatedDocs.add(docKey);
    }
  }
  
  static void _applyBarDefaults(String barId, Map<String, dynamic> data, List<String> missing) {
    if (!autoApplyDefaults && !autoUpdateOnce) return;
    
    final docKey = 'bars/$barId';
    if (autoUpdateOnce && _updatedDocs.contains(docKey)) return;
    
    final updates = <String, dynamic>{};
    
    // Aplicar defaults para campos missing
    for (final field in missing) {
      if (field.startsWith(FirestoreKeys.barStatus)) {
        updates[FirestoreKeys.barStatus] = FirestoreKeys.statusActive;
      } else if (field.startsWith(FirestoreKeys.barProfile)) {
        updates[FirestoreKeys.barProfile] = {
          FirestoreKeys.profileContactsComplete: false,
          FirestoreKeys.profileAddressComplete: false,
        };
      }
    }
    
    if (updates.isNotEmpty) {
      _performUpdate('bars', barId, updates);
      if (autoUpdateOnce) _updatedDocs.add(docKey);
    }
  }
  
  static void _applyEventDefaults(String barId, String eventId, Map<String, dynamic> data, List<String> missing) {
    if (!autoApplyDefaults && !autoUpdateOnce) return;
    
    final docKey = 'bars/$barId/events/$eventId';
    if (autoUpdateOnce && _updatedDocs.contains(docKey)) return;
    
    final updates = <String, dynamic>{};
    
    // Aplicar defaults para campos missing
    for (final field in missing) {
      if (field.startsWith(FirestoreKeys.eventPublished)) {
        updates[FirestoreKeys.eventPublished] = false;
      } else if (field.startsWith(FirestoreKeys.eventAttractions)) {
        updates[FirestoreKeys.eventAttractions] = <String>[];
      }
    }
    
    if (updates.isNotEmpty) {
      FirebaseFirestore.instance
          .collection(FirestoreKeys.barsCollection)
          .doc(barId)
          .collection(FirestoreKeys.eventsSubcollection)
          .doc(eventId)
          .update(updates)
          .then((_) => developer.log('[$_tag] Applied defaults to document', name: _tag))
          .catchError((e) => developer.log('[$_tag] Failed to update document: ${e.runtimeType}', name: _tag));
      
      if (autoUpdateOnce) _updatedDocs.add(docKey);
    }
  }
  
  static void _performUpdate(String collection, String docId, Map<String, dynamic> updates) {
    FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .update(updates)
        .then((_) => developer.log('[$_tag] Applied defaults to document', name: _tag))
        .catchError((e) => developer.log('[$_tag] Failed to update document: ${e.runtimeType}', name: _tag));
  }
}