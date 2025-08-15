import 'package:bar_boss_mobile/app/domain/entities/user_profile.dart';

/// Interface de domínio para gerenciamento de usuários
abstract class UserRepository {
  /// Busca o perfil do usuário atual
  Future<UserProfile?> getMe();

  /// Cria ou atualiza o perfil do usuário
  Future<void> upsert(UserProfile data);
}