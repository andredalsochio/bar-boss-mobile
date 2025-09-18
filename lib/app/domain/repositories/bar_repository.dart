import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';

/// Interface de domínio para operações com bares
/// Isolada de tipos específicos do Firebase
abstract class BarRepository {
  /// Cria um novo bar com reserva de nome
  Future<void> createBarWithReservation({
    required BarModel bar,
    required String primaryOwnerUid,
  });

  /// Cria um novo bar
  Future<String> createBar(BarModel bar);

  /// Atualiza um bar existente
  Future<void> updateBar(BarModel bar);

  /// Obtém um bar pelo ID
  Future<BarModel?> getBarById(String barId);

  /// Obtém bares por proprietário
  Future<List<BarModel>> getBarsByOwner(String primaryOwnerUid);

  /// Obtém stream de bares por proprietário
  Stream<List<BarModel>> getBarsStream(String primaryOwnerUid);

  /// Verifica se um usuário tem bares cadastrados
  Future<bool> hasUserRegisteredBars(String userUid);

  /// Deleta um bar
  Future<void> deleteBar(String barId);

  /// Verifica se um CNPJ já está em uso
  Future<bool> isCnpjInUse(String cnpj);

  /// Verifica se um nome de bar já está em uso
  Future<bool> isBarNameInUse(String name);

  /// Obtém um bar pelo email de contato
  Future<BarModel?> getBarByContactEmail(String email);

  /// Lista os bares em que o usuário é membro
  Future<List<BarModel>> listBarsByMembership(String uid);
}