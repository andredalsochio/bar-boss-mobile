import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';

/// Modelo de dados para registro de CNPJ (/cnpj_registry/{cnpj})
/// Usado para evitar duplicação de CNPJs entre diferentes bares
class CnpjRegistryModel {
  final String cnpj;
  final String barId;
  final String reservedByUid;
  final DateTime createdAt;

  CnpjRegistryModel({
    required this.cnpj,
    required this.barId,
    required this.reservedByUid,
    required this.createdAt,
  });

  /// Cria uma instância vazia com valores padrão
  factory CnpjRegistryModel.empty() {
    return CnpjRegistryModel(
      cnpj: '',
      barId: '',
      reservedByUid: '',
      createdAt: DateTime.now(),
    );
  }

  /// Cria uma instância a partir de um documento do Firestore
  factory CnpjRegistryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CnpjRegistryModel(
      cnpj: doc.id,
      barId: data[FirestoreKeys.cnpjRegistryBarId] ?? '',
      reservedByUid: data[FirestoreKeys.cnpjRegistryReservedByUid] ?? '',
      createdAt: (data[FirestoreKeys.cnpjRegistryCreatedAt] as Timestamp).toDate(),
    );
  }

  /// Converte o modelo para um mapa para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      FirestoreKeys.cnpjRegistryBarId: barId,
      FirestoreKeys.cnpjRegistryReservedByUid: reservedByUid,
      FirestoreKeys.cnpjRegistryCreatedAt: Timestamp.fromDate(createdAt),
    };
  }

  /// Cria uma cópia do modelo com campos atualizados
  CnpjRegistryModel copyWith({
    String? cnpj,
    String? barId,
    String? reservedByUid,
    DateTime? createdAt,
  }) {
    return CnpjRegistryModel(
      cnpj: cnpj ?? this.cnpj,
      barId: barId ?? this.barId,
      reservedByUid: reservedByUid ?? this.reservedByUid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'CnpjRegistryModel(cnpj: $cnpj, barId: $barId, reservedByUid: $reservedByUid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CnpjRegistryModel && other.cnpj == cnpj;
  }

  @override
  int get hashCode => cnpj.hashCode;
}