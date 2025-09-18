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
    required String primaryOwnerUid,
    String? forcedBarId,
  });

  /// Cria um bar de forma simples sem batch complexo
  /// Usado especialmente para fluxo social
  Future<void> createBarSimple(BarModel bar);

  /// Atualiza os dados de um bar
  Future<void> update(BarModel bar);

  /// Lista os bares em que o usuário é membro
  /// Utiliza collectionGroup('members') para buscar por uid
  Stream<List<BarModel>> listMyBars(String uid);

  /// Busca os bares do usuário (versão Future)
  /// Utiliza collectionGroup('members') para buscar por uid
  Future<List<BarModel>> getUserBars(String uid);

  /// Adiciona um membro ao bar com a role especificada
  Future<void> addMember(String barId, String uid, String role);

  /// Verifica se um email está disponível (único)
  Future<bool> isEmailUnique(String email);

  /// Verifica se um CNPJ está disponível (único)
  Future<bool> isCnpjUnique(String cnpj);

  /// Verifica se um CNPJ já existe (via Callable Function)
  Future<bool> checkCnpjExists(String cnpjClean);

  /// Busca um bar por ID
  Future<BarModel?> getById(String barId);

  /// Garante que o usuário seja membro do bar (cria membership se não existir)
  Future<void> ensureMembership(String barId, String uid);
}