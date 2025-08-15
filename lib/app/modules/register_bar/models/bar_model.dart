import 'package:bar_boss_mobile/app/core/schema/firestore_keys.dart';

/// Modelo de endereço do bar
class BarAddress {
  final String cep;
  final String street;
  final String number;
  final String? complement;
  final String state;
  final String city;

  BarAddress({
    required this.cep,
    required this.street,
    required this.number,
    this.complement,
    required this.state,
    required this.city,
  });

  factory BarAddress.empty() {
    return BarAddress(
      cep: '',
      street: '',
      number: '',
      complement: null,
      state: '',
      city: '',
    );
  }

  factory BarAddress.fromMap(Map<String, dynamic> map) {
    return BarAddress(
      cep: map[FirestoreKeys.addressCep] ?? '',
      street: map[FirestoreKeys.addressStreet] ?? '',
      number: map[FirestoreKeys.addressNumber] ?? '',
      complement: map[FirestoreKeys.addressComplement],
      state: map[FirestoreKeys.addressState] ?? '',
      city: map[FirestoreKeys.addressCity] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirestoreKeys.addressCep: cep,
      FirestoreKeys.addressStreet: street,
      FirestoreKeys.addressNumber: number,
      if (complement != null && complement!.isNotEmpty)
        FirestoreKeys.addressComplement: complement,
      FirestoreKeys.addressState: state,
      FirestoreKeys.addressCity: city,
    };
  }

  BarAddress copyWith({
    String? cep,
    String? street,
    String? number,
    String? complement,
    String? state,
    String? city,
  }) {
    return BarAddress(
      cep: cep ?? this.cep,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      state: state ?? this.state,
      city: city ?? this.city,
    );
  }
}

/// Modelo de perfil do bar
class BarProfile {
  final bool contactsComplete;
  final bool addressComplete;

  BarProfile({
    required this.contactsComplete,
    required this.addressComplete,
  });

  factory BarProfile.empty() {
    return BarProfile(
      contactsComplete: false,
      addressComplete: false,
    );
  }

  factory BarProfile.fromMap(Map<String, dynamic> map) {
    return BarProfile(
      contactsComplete: map['contactsComplete'] ?? false,
      addressComplete: map['addressComplete'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contactsComplete': contactsComplete,
      'addressComplete': addressComplete,
    };
  }

  BarProfile copyWith({
    bool? contactsComplete,
    bool? addressComplete,
  }) {
    return BarProfile(
      contactsComplete: contactsComplete ?? this.contactsComplete,
      addressComplete: addressComplete ?? this.addressComplete,
    );
  }
}

/// Modelo de dados para bares no novo sistema multi-bar/multi-usuário
class BarModel {
  final String id;
  final String name;
  final String cnpj;
  final String responsibleName;
  final String contactEmail;
  final String contactPhone;
  final BarAddress address;
  final BarProfile profile;
  final String status;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdByUid;
  final String? primaryOwnerUid;
  
  BarModel({
    required this.id,
    required this.name,
    required this.cnpj,
    required this.responsibleName,
    required this.contactEmail,
    required this.contactPhone,
    required this.address,
    required this.profile,
    required this.status,
    this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByUid,
    this.primaryOwnerUid,
  });
  
  /// Cria uma instância vazia com valores padrão
  factory BarModel.empty() {
    final now = DateTime.now();
    return BarModel(
      id: '',
      name: '',
      cnpj: '',
      responsibleName: '',
      contactEmail: '',
      contactPhone: '',
      address: BarAddress.empty(),
      profile: BarProfile.empty(),
      status: 'active',
      logoUrl: null,
      createdAt: now,
      updatedAt: now,
      createdByUid: '',
      primaryOwnerUid: null,
    );
  }
  
  /// Cria uma instância a partir de um mapa de dados
  factory BarModel.fromMap(Map<String, dynamic> data, String id) {
    return BarModel(
      id: id,
      name: data[FirestoreKeys.barName] ?? '',
      cnpj: data[FirestoreKeys.barCnpj] ?? '',
      responsibleName: data[FirestoreKeys.barResponsibleName] ?? '',
      contactEmail: data[FirestoreKeys.barContactEmail] ?? '',
      contactPhone: data[FirestoreKeys.barContactPhone] ?? '',
      address: BarAddress.fromMap(data['address'] ?? {}),
      profile: BarProfile.fromMap(data['profile'] ?? {}),
      status: data['status'] ?? 'active',
      logoUrl: data['logoUrl'],
      createdAt: _parseDateTime(data[FirestoreKeys.createdAt]),
      updatedAt: _parseDateTime(data[FirestoreKeys.updatedAt]),
      createdByUid: data['createdByUid'] ?? '',
      primaryOwnerUid: data['primaryOwnerUid'],
    );
  }

  /// Converte diferentes tipos de data para DateTime
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    // Para Timestamp do Firestore (quando usado via adapter)
    if (value.runtimeType.toString() == 'Timestamp') {
      return (value as dynamic).toDate();
    }
    return DateTime.now();
  }
  
  /// Converte o modelo para um mapa
  Map<String, dynamic> toMap() {
    return {
      FirestoreKeys.barName: name,
      FirestoreKeys.barCnpj: cnpj,
      FirestoreKeys.barResponsibleName: responsibleName,
      FirestoreKeys.barContactEmail: contactEmail,
      FirestoreKeys.barContactPhone: contactPhone,
      'address': address.toMap(),
      'profile': profile.toMap(),
      'status': status,
      if (logoUrl != null) 'logoUrl': logoUrl,
      FirestoreKeys.createdAt: createdAt,
      FirestoreKeys.updatedAt: updatedAt,
      'createdByUid': createdByUid,
      if (primaryOwnerUid != null) 'primaryOwnerUid': primaryOwnerUid,
    };
  }
  
  /// Cria uma cópia do modelo com os campos atualizados
  BarModel copyWith({
    String? id,
    String? name,
    String? cnpj,
    String? responsibleName,
    String? contactEmail,
    String? contactPhone,
    BarAddress? address,
    BarProfile? profile,
    String? status,
    String? logoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByUid,
    String? primaryOwnerUid,
  }) {
    return BarModel(
      id: id ?? this.id,
      name: name ?? this.name,
      cnpj: cnpj ?? this.cnpj,
      responsibleName: responsibleName ?? this.responsibleName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      address: address ?? this.address,
      profile: profile ?? this.profile,
      status: status ?? this.status,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByUid: createdByUid ?? this.createdByUid,
      primaryOwnerUid: primaryOwnerUid ?? this.primaryOwnerUid,
    );
  }

  /// Verifica se o bar está ativo
  bool get isActive => status == 'active';

  /// Verifica se o perfil de contatos está completo
  bool get hasCompleteContacts => profile.contactsComplete;

  /// Verifica se o perfil de endereço está completo
  bool get hasCompleteAddress => profile.addressComplete;

  /// Verifica se o perfil do bar está totalmente completo
  bool get isProfileComplete => hasCompleteContacts && hasCompleteAddress;

  @override
  String toString() {
    return 'BarModel(id: $id, name: $name, cnpj: ***.***.***-**, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BarModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}