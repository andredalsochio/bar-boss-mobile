/// Estados do processo de cadastro de bar
enum RegistrationState {
  /// Estado inicial
  initial,
  
  /// Carregando
  loading,
  
  /// Sucesso
  success,
  
  /// Erro
  error,
}