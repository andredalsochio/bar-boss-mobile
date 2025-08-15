import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_keys.dart';

part 'schemas.freezed.dart';
part 'schemas.g.dart';

/// Schema para documentos de usuário (/users/{uid})
@freezed
class UserSchema with _$UserSchema {
  const factory UserSchema({
    required String email,
    required String displayName,
    String? photoUrl,
    @Default([]) List<String> providers,
    String? currentBarId,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() DateTime? lastLoginAt,
  }) = _UserSchema;

  factory UserSchema.fromJson(Map<String, dynamic> json) => _$UserSchemaFromJson(json);

  /// Converter para usar com Firestore
  static DocumentReference<UserSchema> docRef(String uid) {
    return FirebaseFirestore.instance
        .collection(FirestoreKeys.usersCollection)
        .doc(uid)
        .withConverter<UserSchema>(
          fromFirestore: (snapshot, _) => UserSchema.fromJson(snapshot.data()!),
          toFirestore: (user, _) => user.toJson(),
        );
  }

  static CollectionReference<UserSchema> collection() {
    return FirebaseFirestore.instance
        .collection(FirestoreKeys.usersCollection)
        .withConverter<UserSchema>(
          fromFirestore: (snapshot, _) => UserSchema.fromJson(snapshot.data()!),
          toFirestore: (user, _) => user.toJson(),
        );
  }
}

/// Schema para endereço (nested em BarSchema)
@freezed
class AddressSchema with _$AddressSchema {
  const factory AddressSchema({
    required String cep,
    required String street,
    required String number,
    String? complement,
    required String state,
    required String city,
  }) = _AddressSchema;

  factory AddressSchema.fromJson(Map<String, dynamic> json) => _$AddressSchemaFromJson(json);
}

/// Schema para perfil do bar (nested em BarSchema)
@freezed
class BarProfileSchema with _$BarProfileSchema {
  const factory BarProfileSchema({
    @Default(false) bool contactsComplete,
    @Default(false) bool addressComplete,
  }) = _BarProfileSchema;

  factory BarProfileSchema.fromJson(Map<String, dynamic> json) => _$BarProfileSchemaFromJson(json);
}

/// Schema para documentos de bar (/bars/{barId})
@freezed
class BarSchema with _$BarSchema {
  const factory BarSchema({
    required String name,
    required String cnpj,
    required String responsibleName,
    required String contactEmail,
    required String contactPhone,
    required AddressSchema address,
    @Default(BarProfileSchema()) BarProfileSchema profile,
    @Default('active') String status,
    String? logoUrl,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() DateTime? updatedAt,
    required String createdByUid,
    required String primaryOwnerUid,
  }) = _BarSchema;

  factory BarSchema.fromJson(Map<String, dynamic> json) => _$BarSchemaFromJson(json);

  /// Converter para usar com Firestore
  static DocumentReference<BarSchema> docRef(String barId) {
    return FirebaseFirestore.instance
        .collection(FirestoreKeys.barsCollection)
        .doc(barId)
        .withConverter<BarSchema>(
          fromFirestore: (snapshot, _) => BarSchema.fromJson(snapshot.data()!),
          toFirestore: (bar, _) => bar.toJson(),
        );
  }

  static CollectionReference<BarSchema> collection() {
    return FirebaseFirestore.instance
        .collection(FirestoreKeys.barsCollection)
        .withConverter<BarSchema>(
          fromFirestore: (snapshot, _) => BarSchema.fromJson(snapshot.data()!),
          toFirestore: (bar, _) => bar.toJson(),
        );
  }
}

/// Schema para membros do bar (/bars/{barId}/members/{uid})
@freezed
class MemberSchema with _$MemberSchema {
  const factory MemberSchema({
    required String uid,
    required String role, // OWNER, ADMIN, EDITOR
    String? invitedByUid,
    @TimestampConverter() required DateTime createdAt,
  }) = _MemberSchema;

  factory MemberSchema.fromJson(Map<String, dynamic> json) => _$MemberSchemaFromJson(json);

  /// Converter para usar com Firestore
  static DocumentReference<MemberSchema> docRef(String barId, String uid) {
    return FirebaseFirestore.instance
        .collection(FirestoreKeys.barsCollection)
        .doc(barId)
        .collection(FirestoreKeys.membersSubcollection)
        .doc(uid)
        .withConverter<MemberSchema>(
          fromFirestore: (snapshot, _) => MemberSchema.fromJson(snapshot.data()!),
          toFirestore: (member, _) => member.toJson(),
        );
  }

  static CollectionReference<MemberSchema> collection(String barId) {
    return FirebaseFirestore.instance
        .collection(FirestoreKeys.barsCollection)
        .doc(barId)
        .collection(FirestoreKeys.membersSubcollection)
        .withConverter<MemberSchema>(
          fromFirestore: (snapshot, _) => MemberSchema.fromJson(snapshot.data()!),
          toFirestore: (member, _) => member.toJson(),
        );
  }
}

/// Schema para eventos (/bars/{barId}/events/{eventId})
@freezed
class EventSchema with _$EventSchema {
  const factory EventSchema({
    required String barId,
    required String title,
    @TimestampConverter() required DateTime startAt,
    @TimestampConverter() DateTime? endAt,
    String? description,
    @Default([]) List<String> attractions,
    String? coverImageUrl,
    @Default(false) bool published,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() DateTime? updatedAt,
    required String createdByUid,
    String? updatedByUid,
  }) = _EventSchema;

  factory EventSchema.fromJson(Map<String, dynamic> json) => _$EventSchemaFromJson(json);

  /// Converter para usar com Firestore
  static DocumentReference<EventSchema> docRef(String barId, String eventId) {
    return FirebaseFirestore.instance
        .collection(FirestoreKeys.barsCollection)
        .doc(barId)
        .collection(FirestoreKeys.eventsSubcollection)
        .doc(eventId)
        .withConverter<EventSchema>(
          fromFirestore: (snapshot, _) => EventSchema.fromJson(snapshot.data()!),
          toFirestore: (event, _) => event.toJson(),
        );
  }

  static CollectionReference<EventSchema> collection(String barId) {
    return FirebaseFirestore.instance
        .collection(FirestoreKeys.barsCollection)
        .doc(barId)
        .collection(FirestoreKeys.eventsSubcollection)
        .withConverter<EventSchema>(
          fromFirestore: (snapshot, _) => EventSchema.fromJson(snapshot.data()!),
          toFirestore: (event, _) => event.toJson(),
        );
  }
}

/// Schema para registro de CNPJ (/cnpj_registry/{cnpj})
@freezed
class CnpjRegistrySchema with _$CnpjRegistrySchema {
  const factory CnpjRegistrySchema({
    required String barId,
    required String reservedByUid,
    @TimestampConverter() required DateTime createdAt,
  }) = _CnpjRegistrySchema;

  factory CnpjRegistrySchema.fromJson(Map<String, dynamic> json) => _$CnpjRegistrySchemaFromJson(json);

  /// Converter para usar com Firestore
  static DocumentReference<CnpjRegistrySchema> docRef(String cnpj) {
    return FirebaseFirestore.instance
        .collection(FirestoreKeys.cnpjRegistryCollection)
        .doc(cnpj)
        .withConverter<CnpjRegistrySchema>(
          fromFirestore: (snapshot, _) => CnpjRegistrySchema.fromJson(snapshot.data()!),
          toFirestore: (registry, _) => registry.toJson(),
        );
  }

  static CollectionReference<CnpjRegistrySchema> collection() {
    return FirebaseFirestore.instance
        .collection(FirestoreKeys.cnpjRegistryCollection)
        .withConverter<CnpjRegistrySchema>(
          fromFirestore: (snapshot, _) => CnpjRegistrySchema.fromJson(snapshot.data()!),
          toFirestore: (registry, _) => registry.toJson(),
        );
  }
}

/// Converter personalizado para Timestamp do Firestore
class TimestampConverter implements JsonConverter<DateTime, Object> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object json) {
    if (json is Timestamp) {
      return json.toDate();
    }
    if (json is String) {
      return DateTime.parse(json);
    }
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    throw ArgumentError('Cannot convert $json to DateTime');
  }

  @override
  Object toJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}