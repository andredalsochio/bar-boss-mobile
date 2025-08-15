import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';

/// Modelo de dados para eventos no novo sistema multi-bar/multi-usuário
/// Eventos agora são subcoleções de bares: /bars/{barId}/events/{eventId}
class EventModel {
  final String id;
  final String barId;
  final String title;
  final DateTime startAt;
  final DateTime? endAt;
  final String? description;
  final List<String>? attractions;
  final String? coverImageUrl;
  final bool published;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdByUid;
  final String? updatedByUid;
  
  EventModel({
    required this.id,
    required this.barId,
    required this.title,
    required this.startAt,
    this.endAt,
    this.description,
    this.attractions,
    this.coverImageUrl,
    this.published = false,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByUid,
    this.updatedByUid,
  });
  
  /// Cria uma instância vazia com valores padrão
  factory EventModel.empty() {
    final now = DateTime.now();
    return EventModel(
      id: '',
      barId: '',
      title: '',
      startAt: now,
      endAt: null,
      description: null,
      attractions: [],
      coverImageUrl: null,
      published: false,
      createdAt: now,
      updatedAt: now,
      createdByUid: '',
      updatedByUid: null,
    );
  }
  
  /// Cria uma instância a partir de um mapa de dados
  factory EventModel.fromMap(Map<String, dynamic> data, String id) {
    return EventModel(
      id: id,
      barId: data[FirestoreKeys.eventBarId] ?? '',
      title: data[FirestoreKeys.eventTitle] ?? '',
      startAt: _parseDateTime(data[FirestoreKeys.eventStartAt]),
      endAt: data[FirestoreKeys.eventEndAt] != null
          ? _parseDateTime(data[FirestoreKeys.eventEndAt])
          : null,
      description: data[FirestoreKeys.eventDescription],
      attractions: data[FirestoreKeys.eventAttractions] != null
          ? List<String>.from(data[FirestoreKeys.eventAttractions])
          : null,
      coverImageUrl: data[FirestoreKeys.eventCoverImageUrl],
      published: data[FirestoreKeys.eventPublished] ?? false,
      createdAt: _parseDateTime(data[FirestoreKeys.eventCreatedAt]),
      updatedAt: _parseDateTime(data[FirestoreKeys.eventUpdatedAt]),
      createdByUid: data[FirestoreKeys.eventCreatedByUid] ?? '',
      updatedByUid: data[FirestoreKeys.eventUpdatedByUid],
    );
  }
  
  /// Helper method para converter diferentes tipos de data para DateTime
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    // Para compatibilidade com Timestamp do Firestore
    if (value.runtimeType.toString() == 'Timestamp') {
      return (value as dynamic).toDate();
    }
    return DateTime.now();
  }
  
  /// Converte o modelo para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barId': barId,
      'title': title,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
      'description': description,
      'attractions': attractions,
      'coverImageUrl': coverImageUrl,
      'published': published,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdByUid': createdByUid,
      'updatedByUid': updatedByUid,
    };
  }
  
  /// Cria uma cópia do modelo com os campos atualizados
  EventModel copyWith({
    String? id,
    String? barId,
    String? title,
    DateTime? startAt,
    DateTime? endAt,
    String? description,
    List<String>? attractions,
    String? coverImageUrl,
    bool? published,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByUid,
    String? updatedByUid,
  }) {
    return EventModel(
      id: id ?? this.id,
      barId: barId ?? this.barId,
      title: title ?? this.title,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      description: description ?? this.description,
      attractions: attractions ?? this.attractions,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      published: published ?? this.published,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByUid: createdByUid ?? this.createdByUid,
      updatedByUid: updatedByUid ?? this.updatedByUid,
    );
  }

  /// Verifica se o evento está publicado
  bool get isPublished => published;

  /// Verifica se o evento já terminou
  bool get hasEnded {
    final now = DateTime.now();
    return endAt != null ? endAt!.isBefore(now) : startAt.isBefore(now);
  }

  /// Verifica se o evento está acontecendo agora
  bool get isHappening {
    final now = DateTime.now();
    if (endAt != null) {
      return startAt.isBefore(now) && endAt!.isAfter(now);
    }
    return startAt.isBefore(now) && startAt.add(Duration(hours: 6)).isAfter(now);
  }

  /// Verifica se o evento é futuro
  bool get isFuture => startAt.isAfter(DateTime.now());

  /// Retorna a duração do evento em horas
  int get durationInHours {
    if (endAt != null) {
      return endAt!.difference(startAt).inHours;
    }
    return 6; // Duração padrão de 6 horas
  }

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, barId: $barId, startAt: $startAt, published: $published)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}