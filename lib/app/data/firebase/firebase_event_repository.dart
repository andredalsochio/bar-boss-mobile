import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/domain/repositories/event_repository_domain.dart';
import 'package:bar_boss_mobile/app/modules/events/models/event_model.dart';
import 'package:bar_boss_mobile/app/core/schema/firestore_keys.dart';
import 'package:bar_boss_mobile/app/data/adapters/event_adapter.dart';

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
        .where(FirestoreKeys.eventPublished, isEqualTo: true) // considera apenas eventos publicados
        .orderBy(FirestoreKeys.eventStartAt, descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventAdapter.fromFirestore(doc))
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
      final eventData = EventAdapter.toFirestore(eventWithIds)
        ..addAll({
          'createdAt': _now,
          'updatedAt': _now,
        });

      await _eventsCollection(barId).doc(eventId).set(eventData);
      return eventId;
    } catch (e) {
      throw Exception('Erro ao criar evento: $e');
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
        EventAdapter.toFirestore(event)..addAll({'updatedAt': _now}),
      );
    } catch (e) {
      throw Exception('Erro ao atualizar evento: $e');
    }
  }

  @override
  Future<void> delete(String barId, String eventId) async {
    try {
      await _eventsCollection(barId).doc(eventId).delete();
    } catch (e) {
      throw Exception('Erro ao excluir evento: $e');
    }
  }

  /// Valida se endAt é null ou >= startAt
  bool _validateEventDates(EventModel event) {
    if (event.endAt == null) return true;
    return event.endAt!.isAfter(event.startAt) || 
           event.endAt!.isAtSameMomentAs(event.startAt);
  }
}