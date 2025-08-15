import 'package:bar_boss_mobile/app/domain/repositories/event_repository.dart';
import 'package:bar_boss_mobile/app/domain/repositories/event_repository_domain.dart';
import 'package:bar_boss_mobile/app/modules/events/models/event_model.dart';

/// Adaptador para compatibilizar EventRepositoryDomain com a interface EventRepository legacy
/// Traduz chamadas dos ViewModels para a interface de domínio moderna
class EventRepositoryAdapter implements EventRepository {
  final EventRepositoryDomain _domainRepository;

  EventRepositoryAdapter(this._domainRepository);

  @override
  Future<String> createEvent(EventModel event) async {
    return await _domainRepository.create(event.barId, event);
  }

  @override
  Future<void> updateEvent(EventModel event) async {
    await _domainRepository.update(event.barId, event);
  }

  @override
  Future<EventModel?> getEventById(String eventId) async {
    // EventRepositoryDomain não tem getEventById sem barId
    throw UnsupportedError('Use getEventById(barId, eventId) ou carregue eventos via stream');
  }

  @override
  Future<List<EventModel>> getEventsByBar(String barId) async {
    // Usa stream e pega o primeiro valor
    final stream = _domainRepository.upcomingByBar(barId);
    return await stream.first;
  }

  @override
  Stream<List<EventModel>> getEventsStream(String barId) {
    return _domainRepository.upcomingByBar(barId);
  }

  @override
  Future<List<EventModel>> getUpcomingEventsByBar(String barId) async {
    final stream = _domainRepository.upcomingByBar(barId);
    return await stream.first;
  }

  @override
  Future<List<EventModel>> getPastEventsByBar(String barId) async {
    // EventRepositoryDomain não implementa eventos passados
    throw UnsupportedError('Eventos passados não são suportados pela interface de domínio');
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    // EventRepositoryDomain requer barId para delete
    throw UnsupportedError('Use deleteEvent(barId, eventId) com o ID do bar');
  }

  @override
  Future<bool> hasEventOnDate(String barId, DateTime date) async {
    // Implementação simples: busca eventos e verifica se há algum na data
    final events = await getUpcomingEventsByBar(barId);
    return events.any((event) => 
      event.startAt.year == date.year &&
      event.startAt.month == date.month &&
      event.startAt.day == date.day
    );
  }

  @override
  Future<List<EventModel>> getEventsByBarId(String barId) async {
    return await getEventsByBar(barId);
  }

  @override
  Future<List<EventModel>> getUpcomingEventsByBarId(String barId) async {
    return await getUpcomingEventsByBar(barId);
  }

  /// Método auxiliar para deletar evento com barId conhecido
  Future<void> deleteEventWithBarId(String barId, String eventId) async {
    await _domainRepository.delete(barId, eventId);
  }
}