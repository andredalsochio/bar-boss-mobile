import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';

/// Interface de domínio para gerenciamento de bares
abstract class BarRepositoryDomain {
  /// Cria um bar com reserva de CNPJ e adiciona o criador como membro OWNER
  /// Retorna o ID do bar criado
  @Deprecated('Use createBarWithReservation para operações atômicas')
  Future<String> create(BarModel bar);

  /// Cria um bar com operação atômica (reserva CNPJ + bar + membership OWNER)
  /// Retorna o ID do bar criado
  Future<String> createBarWithReservation({
    required BarModel bar,
    required String ownerUid,
    String? forcedBarId,
  });

  /// Atualiza os dados de um bar
  Future<void> update(BarModel bar);

  /// Lista os bares em que o usuário é membro
  /// Utiliza collectionGroup('members') para buscar por uid
  Stream<List<BarModel>> listMyBars(String uid);

  /// Adiciona um membro ao bar com a role especificada
  Future<void> addMember(String barId, String uid, String role);

  /// Verifica se um CNPJ já está em uso via /cnpj_registry
  Future<bool> isCnpjInUse(String cnpj);
}