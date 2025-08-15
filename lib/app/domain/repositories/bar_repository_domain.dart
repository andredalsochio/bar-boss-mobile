import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';

/// Interface de domínio para gerenciamento de bares
abstract class BarRepositoryDomain {
  /// Cria um bar com reserva de CNPJ e adiciona o criador como membro OWNER
  /// Retorna o ID do bar criado
  Future<String> create(BarModel bar);

  /// Atualiza os dados de um bar
  Future<void> update(BarModel bar);

  /// Lista os bares em que o usuário é membro
  /// Utiliza collectionGroup('members') para buscar por uid
  Stream<List<BarModel>> listMyBars(String uid);

  /// Adiciona um membro ao bar com a role especificada
  Future<void> addMember(String barId, String uid, String role);
}