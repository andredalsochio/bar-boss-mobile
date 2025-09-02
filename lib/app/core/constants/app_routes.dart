/// Classe que contém as rotas utilizadas no aplicativo
class AppRoutes {
  // Rotas de autenticação
  static const String login = '/login';
  
  // Rotas de cadastro
  static const String registerStep1 = '/register/step1';
  static const String registerStep2 = '/register/step2';
  static const String registerStep3 = '/register/step3';
  static const String registerBarStep1 = '/register/step1';
  static const String registerBarStep2 = '/register/step2';
  static const String registerBarStep3 = '/register/step3';
  
  // Rotas principais
  static const String home = '/';
  static const String barProfile = '/bar-profile';
  static const String settings = '/settings';
  static const String eventsList = '/events';
  static const String eventForm = '/events/form';
  static const String eventEdit = '/events/edit/:id';
  static const String eventDetails = '/events/details/:id';
  
  // Funções auxiliares para rotas com parâmetros
  static String eventEditPath(String id) => '/events/edit/$id';
  static String eventDetailsPath(String id) => '/events/details/$id';
}