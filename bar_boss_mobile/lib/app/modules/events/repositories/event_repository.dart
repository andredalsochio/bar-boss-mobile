import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';
import 'package:bar_boss_mobile/app/modules/events/models/event_model.dart';

/// Repositório para gerenciar os dados dos eventos no Firestore
class EventRepository {
  final FirebaseFirestore _firestore;
  
  EventRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Referência para a coleção de eventos
  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection(FirestoreKeys.eventsCollection);
  
  /// Busca um evento pelo ID
  Future<EventModel?> getEventById(String id) async {
    try {
      final docSnapshot = await _eventsCollection.doc(id).get();
      if (docSnapshot.exists) {
        return EventModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Busca todos os eventos de um bar
  Future<List<EventModel>> getEventsByBarId(String barId) async {
    try {
      final querySnapshot = await _eventsCollection
          .where(FirestoreKeys.barId, isEqualTo: barId)
          .orderBy(FirestoreKeys.eventDate, descending: false)
          .get();
      
      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
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
      final querySnapshot = await _eventsCollection
          .where(FirestoreKeys.barId, isEqualTo: barId)
          .where(FirestoreKeys.eventDate,
              isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy(FirestoreKeys.eventDate, descending: false)
          .get();
      
      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
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
      
      final querySnapshot = await _eventsCollection
          .where(FirestoreKeys.barId, isEqualTo: barId)
          .where(FirestoreKeys.eventDate,
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where(FirestoreKeys.eventDate,
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy(FirestoreKeys.eventDate, descending: false)
          .get();
      
      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Cria um novo evento
  Future<String> createEvent(EventModel event) async {
    try {
      final docRef = await _eventsCollection.add(event.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Atualiza um evento existente
  Future<void> updateEvent(EventModel event) async {
    try {
      await _eventsCollection.doc(event.id).update(event.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  /// Exclui um evento
  Future<void> deleteEvent(String id) async {
    try {
      await _eventsCollection.doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Stream de eventos de um bar
  Stream<List<EventModel>> streamEventsByBarId(String barId) {
    return _eventsCollection
        .where(FirestoreKeys.barId, isEqualTo: barId)
        .orderBy(FirestoreKeys.eventDate, descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList());
  }
  
  /// Stream de próximos eventos de um bar
  Stream<List<EventModel>> streamUpcomingEventsByBarId(String barId) {
    final now = DateTime.now();
    return _eventsCollection
        .where(FirestoreKeys.barId, isEqualTo: barId)
        .where(FirestoreKeys.eventDate,
            isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy(FirestoreKeys.eventDate, descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList());
  }
}