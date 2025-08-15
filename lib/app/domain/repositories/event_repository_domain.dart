import 'package:bar_boss_mobile/app/modules/events/models/event_model.dart';

/// Interface de domínio para gerenciamento de eventos
abstract class EventRepositoryDomain {
  /// Stream dos próximos eventos de um bar, ordenados por startAt
  Stream<List<EventModel>> upcomingByBar(String barId);

  /// Cria um novo evento em um bar
  /// Retorna o ID do evento criado
  Future<String> create(String barId, EventModel event);

  /// Atualiza um evento existente
  Future<void> update(String barId, EventModel event);

  /// Exclui um evento
  Future<void> delete(String barId, String eventId);
}