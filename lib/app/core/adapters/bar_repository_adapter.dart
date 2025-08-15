import 'package:bar_boss_mobile/app/domain/repositories/bar_repository.dart';
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository_domain.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';

/// Adaptador para compatibilizar BarRepositoryDomain com a interface BarRepository legacy
/// Traduz chamadas dos ViewModels para a interface de domínio moderna
class BarRepositoryAdapter implements BarRepository {
  final BarRepositoryDomain _domainRepository;

  BarRepositoryAdapter(this._domainRepository);

  @override
  Future<void> createBarWithReservation({
    required BarModel bar,
    required String ownerUid,
  }) async {
    // Configura o uid no bar
    final barWithUid = bar.copyWith(createdByUid: ownerUid);
    await _domainRepository.create(barWithUid);
  }

  @override
  Future<String> createBar(BarModel bar) {
    return _domainRepository.create(bar);
  }

  @override
  Future<void> updateBar(BarModel bar) {
    return _domainRepository.update(bar);
  }

  @override
  Future<BarModel?> getBarById(String barId) {
    // Não é suportado pela interface de domínio
    throw UnsupportedError('Use listMyBars() para acessar bares por membership');
  }

  @override
  Future<List<BarModel>> getBarsByOwner(String ownerUid) async {
    // Usa listMyBars() do domínio
    final barsStream = _domainRepository.listMyBars(ownerUid);
    return await barsStream.first;
  }

  @override
  Stream<List<BarModel>> getBarsStream(String ownerUid) {
    return _domainRepository.listMyBars(ownerUid);
  }

  @override
  Future<bool> hasUserRegisteredBars(String userUid) async {
    final bars = await getBarsByOwner(userUid);
    return bars.isNotEmpty;
  }

  @override
  Future<void> deleteBar(String barId) {
    throw UnsupportedError('Delete não implementado na interface de domínio');
  }

  @override
  Future<bool> isCnpjInUse(String cnpj) {
    throw UnsupportedError('Verificação de CNPJ via tentativa de criação');
  }

  @override
  Future<bool> isBarNameInUse(String name) {
    throw UnsupportedError('Verificação de nome via tentativa de criação');
  }

  @override
  Future<BarModel?> getBarByContactEmail(String email) async {
    // Método deprecado, mas ainda usado pelos ViewModels
    // Retorna null por enquanto - deve ser refatorado para usar membership
    throw UnsupportedError('getBarByContactEmail deprecado. Use membership pattern.');
  }
}