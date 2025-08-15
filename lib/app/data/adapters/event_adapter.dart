import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/modules/events/models/event_model.dart';
import 'package:bar_boss_mobile/app/core/schema/firestore_keys.dart';

/// Adaptador para converter entre EventModel e tipos do Firestore
class EventAdapter {
  /// Converte um DocumentSnapshot do Firestore para EventModel
  static EventModel fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return fromMap(data, doc.id);
  }

  /// Converte um Map para EventModel
  static EventModel fromMap(Map<String, dynamic> data, String id) {
    return EventModel(
      id: id,
      barId: data[FirestoreKeys.eventBarId] ?? '',
      title: data[FirestoreKeys.eventTitle] ?? '',
      startAt: _timestampToDateTime(data[FirestoreKeys.eventStartAt]),
      endAt: data[FirestoreKeys.eventEndAt] != null
          ? _timestampToDateTime(data[FirestoreKeys.eventEndAt])
          : null,
      description: data[FirestoreKeys.eventDescription],
      attractions: data[FirestoreKeys.eventAttractions] != null
          ? List<String>.from(data[FirestoreKeys.eventAttractions])
          : null,
      coverImageUrl: data[FirestoreKeys.eventCoverImageUrl],
      published: data[FirestoreKeys.eventPublished] ?? false,
      createdAt: _timestampToDateTime(data[FirestoreKeys.eventCreatedAt]),
      updatedAt: _timestampToDateTime(data[FirestoreKeys.eventUpdatedAt]),
      createdByUid: data[FirestoreKeys.eventCreatedByUid] ?? '',
      updatedByUid: data[FirestoreKeys.eventUpdatedByUid],
    );
  }

  /// Converte EventModel para Map do Firestore
  static Map<String, dynamic> toFirestore(EventModel event) {
    return {
      FirestoreKeys.eventBarId: event.barId,
      FirestoreKeys.eventTitle: event.title,
      FirestoreKeys.eventStartAt: _dateTimeToTimestamp(event.startAt),
      FirestoreKeys.eventEndAt: event.endAt != null
          ? _dateTimeToTimestamp(event.endAt!)
          : null,
      FirestoreKeys.eventDescription: event.description,
      FirestoreKeys.eventAttractions: event.attractions,
      FirestoreKeys.eventCoverImageUrl: event.coverImageUrl,
      FirestoreKeys.eventPublished: event.published,
      FirestoreKeys.eventCreatedAt: _dateTimeToTimestamp(event.createdAt),
      FirestoreKeys.eventUpdatedAt: _dateTimeToTimestamp(event.updatedAt),
      FirestoreKeys.eventCreatedByUid: event.createdByUid,
      FirestoreKeys.eventUpdatedByUid: event.updatedByUid,
    };
  }

  /// Converte EventModel para Map simples (sem Timestamp)
  static Map<String, dynamic> toMap(EventModel event) {
    return {
      'id': event.id,
      'barId': event.barId,
      'title': event.title,
      'startAt': event.startAt.toIso8601String(),
      'endAt': event.endAt?.toIso8601String(),
      'description': event.description,
      'attractions': event.attractions,
      'coverImageUrl': event.coverImageUrl,
      'published': event.published,
      'createdAt': event.createdAt.toIso8601String(),
      'updatedAt': event.updatedAt.toIso8601String(),
      'createdByUid': event.createdByUid,
      'updatedByUid': event.updatedByUid,
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

  /// Converte DateTime para Timestamp
  static Timestamp _dateTimeToTimestamp(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}