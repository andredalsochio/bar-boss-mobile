import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modules/register_bar/models/bar_model.dart';
import '../../core/constants/firestore_keys.dart';

/// Adaptador para converter entre BarModel e tipos do Firestore
class BarAdapter {
  /// Converte DocumentSnapshot do Firestore para BarModel
  static BarModel fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BarModel(
      id: doc.id,
      name: data[FirestoreKeys.barName] ?? '',
      cnpj: data[FirestoreKeys.barCnpj] ?? '',
      responsibleName: data[FirestoreKeys.barResponsibleName] ?? '',
      contactEmail: data[FirestoreKeys.barContactEmail] ?? '',
      contactPhone: data[FirestoreKeys.barContactPhone] ?? '',
      address: BarAddress.fromMap(data['address'] ?? {}),
      profile: BarProfile.fromMap(data['profile'] ?? {}),
      status: data['status'] ?? 'active',
      logoUrl: data['logoUrl'],
      createdAt: data[FirestoreKeys.createdAt] != null 
          ? (data[FirestoreKeys.createdAt] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data[FirestoreKeys.updatedAt] != null 
          ? (data[FirestoreKeys.updatedAt] as Timestamp).toDate()
          : DateTime.now(),
      createdByUid: data['createdByUid'] ?? '',
      primaryOwnerUid: data['primaryOwnerUid'],
    );
  }

  /// Converte BarModel para Map para salvar no Firestore
  static Map<String, dynamic> toFirestore(BarModel bar) {
    return {
      FirestoreKeys.barName: bar.name,
      FirestoreKeys.barCnpj: bar.cnpj,
      FirestoreKeys.barResponsibleName: bar.responsibleName,
      FirestoreKeys.barContactEmail: bar.contactEmail,
      FirestoreKeys.barContactPhone: bar.contactPhone,
      'address': bar.address.toMap(),
      'profile': bar.profile.toMap(),
      'status': bar.status,
      'logoUrl': bar.logoUrl,
      FirestoreKeys.createdAt: Timestamp.fromDate(bar.createdAt),
      FirestoreKeys.updatedAt: Timestamp.fromDate(bar.updatedAt),
      'createdByUid': bar.createdByUid,
      'primaryOwnerUid': bar.primaryOwnerUid,
    };
  }

  /// Converte Map genérico para BarModel (para uso em testes ou outras fontes)
  static BarModel fromMap(Map<String, dynamic> data, String id) {
    return BarModel(
      id: id,
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

  /// Converte BarModel para Map genérico (para uso em testes ou outras fontes)
  static Map<String, dynamic> toMap(BarModel bar) {
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
  static DateTime _timestampToDateTime(dynamic timestamp) {
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