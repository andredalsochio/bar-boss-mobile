import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:bar_boss_mobile/app/modules/events/models/event_model.dart';
import 'package:bar_boss_mobile/app/core/schema/firestore_keys.dart';

/// Repositório para gerenciar os dados dos eventos no Firestore
/// Eventos agora são subcoleções de bares: /bars/{barId}/events/{eventId}
class EventRepository {
  final FirebaseFirestore _firestore;
  
  EventRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Converte DocumentSnapshot para EventModel
  EventModel _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel.fromMap(data, doc.id);
  }
  
  /// Referência para a subcoleção de eventos de um bar específico
  CollectionReference<Map<String, dynamic>> _eventsCollection(String barId) =>
      _firestore
          .collection(FirestoreKeys.barsCollection)
          .doc(barId)
          .collection(FirestoreKeys.eventsSubcollection);
  
  /// Busca um evento pelo ID dentro de um bar específico
  Future<EventModel?> getEventById(String barId, String eventId) async {
    debugPrint('🔍 [EventRepository] Buscando evento: $eventId do bar $barId');
    try {
      final docSnapshot = await _eventsCollection(barId).doc(eventId).get();
      if (docSnapshot.exists) {
        debugPrint('✅ [EventRepository] Evento encontrado: $eventId');
        return _fromFirestore(docSnapshot);
      }
      debugPrint('🔍 [EventRepository] Evento não encontrado: $eventId');
      return null;
    } catch (e) {
      debugPrint('❌ [EventRepository] Erro ao buscar evento: $e');
      rethrow;
    }
  }
  
  /// Busca todos os eventos de um bar
  Future<List<EventModel>> getEventsByBarId(String barId) async {
    debugPrint('📅 [EventRepository] Buscando todos os eventos do bar: $barId');
    try {
      final querySnapshot = await _eventsCollection(barId)
          .orderBy(FirestoreKeys.eventStartAt, descending: false)
          .get();
      
      final events = querySnapshot.docs
          .map((doc) => _fromFirestore(doc))
          .toList();
      
      debugPrint('✅ [EventRepository] Encontrados ${events.length} eventos para o bar $barId');
      return events;
    } catch (e) {
      debugPrint('❌ [EventRepository] Erro ao buscar eventos do bar: $e');
      rethrow;
    }
  }
  
  /// Busca os próximos eventos de um bar
  Future<List<EventModel>> getUpcomingEventsByBarId(
    String barId, {
    DateTime? fromDate,
  }) async {
    final now = fromDate ?? DateTime.now();
    debugPrint('🔮 [EventRepository] Buscando próximos eventos do bar $barId a partir de $now');
    try {
      final querySnapshot = await _eventsCollection(barId)
          .where(FirestoreKeys.eventStartAt,
              isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy(FirestoreKeys.eventStartAt, descending: false)
          .get();
      
      final events = querySnapshot.docs
          .map((doc) => _fromFirestore(doc))
          .toList();
      
      debugPrint('✅ [EventRepository] Encontrados ${events.length} próximos eventos para o bar $barId');
      return events;
    } catch (e) {
      debugPrint('❌ [EventRepository] Erro ao buscar próximos eventos: $e');
      rethrow;
    }
  }
  
  /// Busca os eventos de um bar por mês
  Future<List<EventModel>> getEventsByBarIdAndMonth(
    String barId,
    int year,
    int month,
  ) async {
    debugPrint('📆 [EventRepository] Buscando eventos do bar $barId para $month/$year');
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
      
      debugPrint('📆 [EventRepository] Período: $startDate até $endDate');
      
      final querySnapshot = await _eventsCollection(barId)
          .where(FirestoreKeys.eventStartAt,
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where(FirestoreKeys.eventStartAt,
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy(FirestoreKeys.eventStartAt, descending: false)
          .get();
      
      final events = querySnapshot.docs
          .map((doc) => _fromFirestore(doc))
          .toList();
      
      debugPrint('✅ [EventRepository] Encontrados ${events.length} eventos para $month/$year');
      return events;
    } catch (e) {
      debugPrint('❌ [EventRepository] Erro ao buscar eventos do mês: $e');
      rethrow;
    }
  }
  
  /// Cria um novo evento
  Future<String> createEvent(EventModel event) async {
    debugPrint('🎉 [EventRepository] Criando evento: ${event.title} para bar ${event.barId}');
    try {
      debugPrint('🎉 [EventRepository] Adicionando documento ao Firestore...');
      final docRef = await _eventsCollection(event.barId).add(event.toMap());
      debugPrint('✅ [EventRepository] Evento criado com sucesso! ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ [EventRepository] Erro ao criar evento: $e');
      rethrow;
    }
  }
  
  /// Atualiza um evento existente
  Future<void> updateEvent(EventModel event) async {
    debugPrint('📝 [EventRepository] Atualizando evento: ${event.id} - ${event.title}');
    try {
      debugPrint('📝 [EventRepository] Atualizando documento no Firestore...');
      await _eventsCollection(event.barId).doc(event.id).update(event.toMap());
      debugPrint('✅ [EventRepository] Evento atualizado com sucesso!');
    } catch (e) {
      debugPrint('❌ [EventRepository] Erro ao atualizar evento: $e');
      rethrow;
    }
  }
  
  /// Exclui um evento
  Future<void> deleteEvent(String barId, String eventId) async {
    debugPrint('🗑️ [EventRepository] Excluindo evento: $eventId do bar $barId');
    try {
      debugPrint('🗑️ [EventRepository] Deletando documento do Firestore...');
      await _eventsCollection(barId).doc(eventId).delete();
      debugPrint('✅ [EventRepository] Evento excluído com sucesso!');
    } catch (e) {
      debugPrint('❌ [EventRepository] Erro ao excluir evento: $e');
      rethrow;
    }
  }
  
  /// Stream de eventos de um bar
  Stream<List<EventModel>> streamEventsByBarId(String barId) {
    return _eventsCollection(barId)
        .orderBy(FirestoreKeys.eventStartAt, descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _fromFirestore(doc))
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
            .map((doc) => _fromFirestore(doc))
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
          .map((doc) => _fromFirestore(doc))
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
            .map((doc) => _fromFirestore(doc))
            .toList());
  }
}