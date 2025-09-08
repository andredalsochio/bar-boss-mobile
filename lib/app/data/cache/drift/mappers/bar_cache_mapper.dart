import 'package:drift/drift.dart';
import '../../../../modules/register_bar/models/bar_model.dart';
import '../cache_database.dart';

/// Mapper para converter entre BarModel e CachedBar (Drift)
class BarCacheMapper {
  /// Converte BarModel para CachedBarsCompanion (para inserção/atualização)
  static CachedBarsCompanion toCompanion(BarModel bar) {
    final now = DateTime.now();
    return CachedBarsCompanion(
      id: Value(bar.id),
      name: Value(bar.name),
      cnpj: Value(bar.cnpj),
      contactEmail: Value(bar.contactEmail),
      responsibleName: Value(bar.responsibleName),
      phone: Value(bar.contactPhone),
      cep: Value(bar.address.cep),
      street: Value(bar.address.street),
      number: Value(bar.address.number),
      complement: Value(bar.address.complement ?? ''),
      neighborhood: Value(''), // Campo não existe no BarModel atual
      city: Value(bar.address.city),
      state: Value(bar.address.state),
      ownerUid: Value(bar.createdByUid),
      createdAt: Value(bar.createdAt),
      updatedAt: Value(bar.updatedAt),
      cacheCreatedAt: Value(now),
      cacheUpdatedAt: Value(now),
    );
  }

  /// Converte CachedBar para BarModel
  static BarModel fromCached(CachedBar cached) {
    return BarModel(
      id: cached.id,
      name: cached.name,
      cnpj: cached.cnpj,
      responsibleName: cached.responsibleName,
      contactEmail: cached.contactEmail,
      contactPhone: cached.phone,
      address: BarAddress(
        cep: cached.cep,
        street: cached.street,
        number: cached.number,
        complement: cached.complement.isEmpty ? null : cached.complement,
        city: cached.city,
        state: cached.state,
      ),
      profile: BarProfile(
        contactsComplete: true, // Assumindo completo se está no cache
        addressComplete: true,
      ),
      status: 'active', // Status padrão
      logoUrl: null,
      createdAt: cached.createdAt,
      updatedAt: cached.updatedAt,
      createdByUid: cached.ownerUid,
      primaryOwnerUid: cached.ownerUid,
    );
  }

  /// Converte BarModel para CachedBarsCompanion para atualização
  static CachedBarsCompanion toUpdateCompanion(
    BarModel bar, {
    bool needsSync = false,
  }) {
    return CachedBarsCompanion(
      id: Value(bar.id),
      name: Value(bar.name),
      cnpj: Value(bar.cnpj),
      contactEmail: Value(bar.contactEmail),
      responsibleName: Value(bar.responsibleName),
      phone: Value(bar.contactPhone),
      cep: Value(bar.address.cep),
      street: Value(bar.address.street),
      number: Value(bar.address.number),
      complement: Value(bar.address.complement ?? ''),
      neighborhood: Value(''),
      city: Value(bar.address.city),
      state: Value(bar.address.state),
      ownerUid: Value(bar.createdByUid),
      createdAt: Value(bar.createdAt),
      updatedAt: Value(bar.updatedAt),
      cacheUpdatedAt: Value(DateTime.now()),
    );
  }

  /// Marca um bar como precisando de sincronização
  static CachedBarsCompanion markForSync(String barId) {
    return CachedBarsCompanion(
      id: Value(barId),
      cacheUpdatedAt: Value(DateTime.now()),
    );
  }

  /// Verifica se o cache expirou (baseado em TTL)
  static bool isExpired(CachedBar cached, Duration ttl) {
    final expirationTime = cached.cacheUpdatedAt.add(ttl);
    return DateTime.now().isAfter(expirationTime);
  }
}