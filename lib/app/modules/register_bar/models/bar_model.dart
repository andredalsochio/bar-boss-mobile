import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';

/// Modelo de dados para bares
class BarModel {
  final String id;
  final String email;
  final String cnpj;
  final String name;
  final String responsibleName;
  final String phone;
  final String cep;
  final String street;
  final String number;
  final String? complement;
  final String state;
  final String city;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  BarModel({
    required this.id,
    required this.email,
    required this.cnpj,
    required this.name,
    required this.responsibleName,
    required this.phone,
    required this.cep,
    required this.street,
    required this.number,
    this.complement,
    required this.state,
    required this.city,
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// Cria uma instância vazia com valores padrão
  factory BarModel.empty() {
    final now = DateTime.now();
    return BarModel(
      id: '',
      email: '',
      cnpj: '',
      name: '',
      responsibleName: '',
      phone: '',
      cep: '',
      street: '',
      number: '',
      complement: '',
      state: '',
      city: '',
      createdAt: now,
      updatedAt: now,
    );
  }
  
  /// Cria uma instância a partir de um documento do Firestore
  factory BarModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BarModel(
      id: doc.id,
      email: data[FirestoreKeys.barEmail] ?? '',
      cnpj: data[FirestoreKeys.barCnpj] ?? '',
      name: data[FirestoreKeys.barName] ?? '',
      responsibleName: data[FirestoreKeys.barResponsibleName] ?? '',
      phone: data[FirestoreKeys.barPhone] ?? '',
      cep: data[FirestoreKeys.barCep] ?? '',
      street: data[FirestoreKeys.barStreet] ?? '',
      number: data[FirestoreKeys.barNumber] ?? '',
      complement: data[FirestoreKeys.barComplement],
      state: data[FirestoreKeys.barState] ?? '',
      city: data[FirestoreKeys.barCity] ?? '',
      createdAt: (data[FirestoreKeys.createdAt] as Timestamp).toDate(),
      updatedAt: (data[FirestoreKeys.updatedAt] as Timestamp).toDate(),
    );
  }
  
  /// Converte o modelo para um mapa para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      FirestoreKeys.barEmail: email,
      FirestoreKeys.barCnpj: cnpj,
      FirestoreKeys.barName: name,
      FirestoreKeys.barResponsibleName: responsibleName,
      FirestoreKeys.barPhone: phone,
      FirestoreKeys.barCep: cep,
      FirestoreKeys.barStreet: street,
      FirestoreKeys.barNumber: number,
      if (complement != null && complement!.isNotEmpty)
        FirestoreKeys.barComplement: complement,
      FirestoreKeys.barState: state,
      FirestoreKeys.barCity: city,
      FirestoreKeys.createdAt: Timestamp.fromDate(createdAt),
      FirestoreKeys.updatedAt: Timestamp.fromDate(DateTime.now()),
    };
  }
  
  /// Cria uma cópia do modelo com os campos atualizados
  BarModel copyWith({
    String? id,
    String? email,
    String? cnpj,
    String? name,
    String? responsibleName,
    String? phone,
    String? cep,
    String? street,
    String? number,
    String? complement,
    String? state,
    String? city,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BarModel(
      id: id ?? this.id,
      email: email ?? this.email,
      cnpj: cnpj ?? this.cnpj,
      name: name ?? this.name,
      responsibleName: responsibleName ?? this.responsibleName,
      phone: phone ?? this.phone,
      cep: cep ?? this.cep,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      state: state ?? this.state,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}