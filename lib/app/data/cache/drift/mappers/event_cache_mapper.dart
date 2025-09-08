import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../../modules/events/models/event_model.dart';
import '../cache_database.dart';

/// Mapper para converter entre EventModel e CachedEvent (Drift)
class EventCacheMapper {
  /// Converte EventModel para CachedEventsCompanion (para inserção)
  static CachedEventsCompanion toCompanion(EventModel event) {
    final now = DateTime.now();
    return CachedEventsCompanion(
      id: Value(event.id),
      barId: Value(event.barId),
      title: Value(event.title),
      startAt: Value(event.startAt),
      endAt: Value(event.endAt),
      description: Value(event.description ?? ''),
      attractions: Value(jsonEncode(event.attractions ?? [])),
      coverImageUrl: Value(event.coverImageUrl ?? ''),
      published: Value(event.published),
      promoDetails: Value(event.promoDetails ?? ''),
      promoImages: Value(jsonEncode(event.promoImages ?? [])),
      createdAt: Value(event.createdAt),
      updatedAt: Value(event.updatedAt),
      createdByUid: Value(event.createdByUid),
      updatedByUid: Value(event.updatedByUid ?? ''),
      cacheCreatedAt: Value(now),
      cacheUpdatedAt: Value(now),
    );
  }

  /// Converte CachedEvent para EventModel
  static EventModel fromCached(CachedEvent cached) {
    List<String> attractions = [];
    List<String> promoImages = [];
    
    try {
      if (cached.attractions.isNotEmpty) {
        attractions = List<String>.from(jsonDecode(cached.attractions));
      }
    } catch (e) {
      // Se falhar ao decodificar, mantém lista vazia
    }
    
    try {
      if (cached.promoImages.isNotEmpty) {
        promoImages = List<String>.from(jsonDecode(cached.promoImages));
      }
    } catch (e) {
      // Se falhar ao decodificar, mantém lista vazia
    }

    return EventModel(
      id: cached.id,
      barId: cached.barId,
      title: cached.title,
      startAt: cached.startAt,
      endAt: cached.endAt,
      description: cached.description.isEmpty ? null : cached.description,
      attractions: attractions.isEmpty ? null : attractions,
      coverImageUrl: (cached.coverImageUrl?.isEmpty ?? true) ? null : cached.coverImageUrl,
      published: cached.published,
      promoDetails: cached.promoDetails.isEmpty ? null : cached.promoDetails,
      promoImages: promoImages.isEmpty ? null : promoImages,
      createdAt: cached.createdAt,
      updatedAt: cached.updatedAt,
      createdByUid: cached.createdByUid,
      updatedByUid: cached.updatedByUid.isEmpty ? null : cached.updatedByUid,
    );
  }

  /// Converte EventModel para CachedEventsCompanion para atualização
  static CachedEventsCompanion toUpdateCompanion(
    EventModel event, {
    bool needsSync = false,
  }) {
    return CachedEventsCompanion(
      id: Value(event.id),
      barId: Value(event.barId),
      title: Value(event.title),
      startAt: Value(event.startAt),
      endAt: Value(event.endAt),
      description: Value(event.description ?? ''),
      attractions: Value(jsonEncode(event.attractions ?? [])),
      coverImageUrl: Value(event.coverImageUrl ?? ''),
      published: Value(event.published),
      promoDetails: Value(event.promoDetails ?? ''),
      promoImages: Value(jsonEncode(event.promoImages ?? [])),
      createdAt: Value(event.createdAt),
      updatedAt: Value(event.updatedAt),
      createdByUid: Value(event.createdByUid),
      updatedByUid: Value(event.updatedByUid ?? ''),
      cacheUpdatedAt: Value(DateTime.now()),
    );
  }

  /// Marca um evento como precisando de sincronização
  static CachedEventsCompanion markForSync(String eventId) {
    return CachedEventsCompanion(
      id: Value(eventId),
      cacheUpdatedAt: Value(DateTime.now()),
    );
  }

  /// Verifica se o cache expirou (baseado em TTL)
  static bool isExpired(CachedEvent cached, Duration ttl) {
    final expirationTime = cached.cacheUpdatedAt.add(ttl);
    return DateTime.now().isAfter(expirationTime);
  }
}