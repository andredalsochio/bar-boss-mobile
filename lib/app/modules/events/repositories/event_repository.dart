import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/modules/events/models/event_model.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';
import 'package:bar_boss_mobile/app/data/adapters/event_adapter.dart';

/// Repositório para gerenciar os dados dos eventos no Firestore
/// Eventos agora são subcoleções de bares: /bars/{barId}/events/{eventId}
class EventRepository {
  final FirebaseFirestore _firestore;
  
  EventRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Referência para a subcoleção de eventos de um bar específico
  CollectionReference<Map<String, dynamic>> _eventsCollection(String barId) =>
      _firestore
          .collection(FirestoreKeys.barsCollection)
          .doc(barId)
          .collection(FirestoreKeys.eventsSubcollection);
  
  /// Busca um evento pelo ID dentro de um bar específico
  Future<EventModel?> getEventById(String barId, String eventId) async {
    try {
      final docSnapshot = await _eventsCollection(barId).doc(eventId).get();
      if (docSnapshot.exists) {
        return EventAdapter.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca todos os eventos de um bar
  Future<List<EventModel>> getEventsByBarId(String barId) async {
    try {
      final querySnapshot = await _eventsCollection(barId)
          .orderBy(FirestoreKeys.eventStartAt, descending: false)
          .get();
      
      return querySnapshot.docs
          .map((doc) => EventAdapter.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca os próximos eventos de um bar
  Future<List<EventModel>> getUpcomingEventsByBarId(
    String barId, {
    DateTime? fromDate,
  }) async {
    try {
      final now = fromDate ?? DateTime.now();
      final querySnapshot = await _eventsCollection(barId)
          .where(FirestoreKeys.eventStartAt,
              isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy(FirestoreKeys.eventStartAt, descending: false)
          .get();
      
      return querySnapshot.docs
          .map((doc) => EventAdapter.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca os eventos de um bar por mês
  Future<List<EventModel>> getEventsByBarIdAndMonth(
    String barId,
    int year,
    int month,
  ) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
      
      final querySnapshot = await _eventsCollection(barId)
          .where(FirestoreKeys.eventStartAt,
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where(FirestoreKeys.eventStartAt,
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy(FirestoreKeys.eventStartAt, descending: false)
          .get();
      
      return querySnapshot.docs
          .map((doc) => EventAdapter.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Cria um novo evento
  Future<String> createEvent(EventModel event) async {
    try {
      final docRef = await _eventsCollection(event.barId).add(EventAdapter.toFirestore(event));
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Atualiza um evento existente
  Future<void> updateEvent(EventModel event) async {
    try {
      await _eventsCollection(event.barId).doc(event.id).update(EventAdapter.toFirestore(event));
    } catch (e) {
      rethrow;
    }
  }
  
  /// Exclui um evento
  Future<void> deleteEvent(String barId, String eventId) async {
    try {
      await _eventsCollection(barId).doc(eventId).delete();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Stream de eventos de um bar
  Stream<List<EventModel>> streamEventsByBarId(String barId) {
    return _eventsCollection(barId)
        .orderBy(FirestoreKeys.eventStartAt, descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventAdapter.fromFirestore(doc))
            .toList());
  }
  
  /// Stream de próximos eventos de um bar
  Stream<List<EventModel>> streamUpcomingEventsByBarId(String barId) {
    final now = DateTime.now();
    return _eventsCollection(barId)
        .where(FirestoreKeys.eventStartAt,
            isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy(FirestoreKeys.eventStartAt, descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventAdapter.fromFirestore(doc))
            .toList());
  }

  /// Busca eventos publicados de um bar
  Future<List<EventModel>> getPublishedEventsByBarId(String barId) async {
    try {
      final querySnapshot = await _eventsCollection(barId)
          .where(FirestoreKeys.eventPublished, isEqualTo: true)
          .orderBy(FirestoreKeys.eventStartAt, descending: false)
          .get();
      
      return querySnapshot.docs
          .map((doc) => EventAdapter.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream de eventos publicados de um bar
  Stream<List<EventModel>> streamPublishedEventsByBarId(String barId) {
    return _eventsCollection(barId)
        .where(FirestoreKeys.eventPublished, isEqualTo: true)
        .orderBy(FirestoreKeys.eventStartAt, descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventAdapter.fromFirestore(doc))
            .toList());
  }
}