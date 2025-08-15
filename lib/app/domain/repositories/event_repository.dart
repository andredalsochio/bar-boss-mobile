import 'package:bar_boss_mobile/app/modules/events/models/event_model.dart';

/// Interface de domínio para operações com eventos
/// Isolada de tipos específicos do Firebase
abstract class EventRepository {
  /// Cria um novo evento
  Future<String> createEvent(EventModel event);

  /// Atualiza um evento existente
  Future<void> updateEvent(EventModel event);

  /// Obtém um evento pelo ID
  Future<EventModel?> getEventById(String eventId);

  /// Obtém eventos por bar
  Future<List<EventModel>> getEventsByBar(String barId);

  /// Obtém stream de eventos por bar
  Stream<List<EventModel>> getEventsStream(String barId);

  /// Obtém eventos futuros por bar
  Future<List<EventModel>> getUpcomingEventsByBar(String barId);

  /// Obtém eventos passados por bar
  Future<List<EventModel>> getPastEventsByBar(String barId);

  /// Deleta um evento
  Future<void> deleteEvent(String eventId);

  /// Verifica se existe evento na data para o bar
  Future<bool> hasEventOnDate(String barId, DateTime date);

  /// Obtém eventos por bar ID (alias para getEventsByBar)
  Future<List<EventModel>> getEventsByBarId(String barId);

  /// Obtém eventos futuros por bar ID (alias para getUpcomingEventsByBar)
  Future<List<EventModel>> getUpcomingEventsByBarId(String barId);
}