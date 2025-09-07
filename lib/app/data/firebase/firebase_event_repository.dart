import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/domain/repositories/event_repository_domain.dart';
import 'package:bar_boss_mobile/app/modules/events/models/event_model.dart';
import 'package:bar_boss_mobile/app/core/schema/firestore_keys.dart';

/// Implementação Firebase da interface EventRepositoryDomain
class FirebaseEventRepository implements EventRepositoryDomain {
  final FirebaseFirestore _firestore;
  
  FirebaseEventRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Referência para a subcoleção de eventos de um bar específico
  CollectionReference<Map<String, dynamic>> _eventsCollection(String barId) =>
      _firestore
          .collection(FirestoreKeys.barsCollection)
          .doc(barId)
          .collection(FirestoreKeys.eventsSubcollection);

  /// Timestamp do servidor
  FieldValue get _now => FieldValue.serverTimestamp();

  @override
  Stream<List<EventModel>> upcomingByBar(String barId) {
    final now = DateTime.now();
    return _eventsCollection(barId)
        .where(FirestoreKeys.eventStartAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy(FirestoreKeys.eventStartAt, descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _fromFirestore(doc))
            .where((event) => _validateEventDates(event)) // valida endAt >= startAt
            .toList());
  }

  /// Stream de eventos publicados futuros de um bar (para exibição pública)
  Stream<List<EventModel>> upcomingPublishedByBar(String barId) {
    final now = DateTime.now();
    return _eventsCollection(barId)
        .where(FirestoreKeys.eventStartAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where(FirestoreKeys.eventPublished, isEqualTo: true) // considera apenas eventos publicados
        .orderBy(FirestoreKeys.eventStartAt, descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _fromFirestore(doc))
            .where((event) => _validateEventDates(event)) // valida endAt >= startAt
            .toList());
  }

  @override
  Future<String> create(String barId, EventModel event) async {
    try {
      // Valida as datas do evento
      if (!_validateEventDates(event)) {
        throw Exception('Data de fim deve ser maior ou igual à data de início');
      }

      final eventId = _eventsCollection(barId).doc().id;
      final eventWithIds = event.copyWith(
        id: eventId,
        barId: barId,
        createdAt: DateTime.now(), // será sobrescrito pelo _now
        updatedAt: DateTime.now(), // será sobrescrito pelo _now
      );
      final eventData = _toFirestore(eventWithIds)
        ..addAll({
          'createdAt': _now,
          'updatedAt': _now,
        });

      await _eventsCollection(barId).doc(eventId).set(eventData);
      return eventId;
    } catch (e) {
      throw Exception('Erro ao criar evento. Tente novamente.');
    }
  }

  @override
  Future<void> update(String barId, EventModel event) async {
    try {
      // Valida as datas do evento
      if (!_validateEventDates(event)) {
        throw Exception('Data de fim deve ser maior ou igual à data de início');
      }

      await _eventsCollection(barId).doc(event.id).update(
        _toFirestore(event)..addAll({'updatedAt': _now}),
      );
    } catch (e) {
      throw Exception('Erro ao atualizar evento. Tente novamente.');
    }
  }

  @override
  Future<void> delete(String barId, String eventId) async {
    try {
      await _eventsCollection(barId).doc(eventId).delete();
    } catch (e) {
      throw Exception('Erro ao excluir evento. Tente novamente.');
    }
  }

  /// Valida se endAt é null ou >= startAt
  bool _validateEventDates(EventModel event) {
    if (event.endAt == null) return true;
    return event.endAt!.isAfter(event.startAt) || 
           event.endAt!.isAtSameMomentAs(event.startAt);
  }

  // Métodos privados de conversão (anteriormente no EventAdapter)
  
  /// Converte DocumentSnapshot do Firestore para EventModel
  EventModel _fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    
    return EventModel(
      id: doc.id,
      barId: data[FirestoreKeys.eventBarId] ?? '',
      title: data[FirestoreKeys.eventTitle] ?? '',
      startAt: _timestampToDateTime(data[FirestoreKeys.eventStartAt]),
      endAt: data[FirestoreKeys.eventEndAt] != null
          ? _timestampToDateTime(data[FirestoreKeys.eventEndAt])
          : null,
      description: data[FirestoreKeys.eventDescription] ?? '',
      attractions: List<String>.from(data[FirestoreKeys.eventAttractions] ?? []),
      coverImageUrl: data[FirestoreKeys.eventCoverImageUrl],
      published: data[FirestoreKeys.eventPublished] ?? false,
      promoDetails: data[FirestoreKeys.eventPromoDetails] ?? '',
      promoImages: List<String>.from(data[FirestoreKeys.eventPromoImages] ?? []),
      createdAt: _timestampToDateTime(data[FirestoreKeys.eventCreatedAt]),
      updatedAt: _timestampToDateTime(data[FirestoreKeys.eventUpdatedAt]),
      createdByUid: data[FirestoreKeys.eventCreatedByUid] ?? '',
      updatedByUid: data[FirestoreKeys.eventUpdatedByUid] ?? '',
    );
  }

  /// Converte EventModel para Map do Firestore (com Timestamp)
  Map<String, dynamic> _toFirestore(EventModel event) {
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
      FirestoreKeys.eventPromoDetails: event.promoDetails,
      FirestoreKeys.eventPromoImages: event.promoImages,
      FirestoreKeys.eventCreatedAt: _dateTimeToTimestamp(event.createdAt),
      FirestoreKeys.eventUpdatedAt: _dateTimeToTimestamp(event.updatedAt),
      FirestoreKeys.eventCreatedByUid: event.createdByUid,
      FirestoreKeys.eventUpdatedByUid: event.updatedByUid,
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

  /// Converte DateTime para Timestamp
  Timestamp _dateTimeToTimestamp(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}