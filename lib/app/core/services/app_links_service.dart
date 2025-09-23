import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';

/// Serviço para gerenciar App Links (substitui Firebase Dynamic Links)
/// Responsável por:
/// - Inicializar listeners de deep links
/// - Processar links de verificação de email
/// - Navegar automaticamente para /login após verificação
/// - Suportar URLs do Firebase Hosting: https://bar-boss-mobile.web.app
class AppLinksService {
  static final AppLinksService _instance = AppLinksService._internal();
  factory AppLinksService() => _instance;
  AppLinksService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  BuildContext? _context;

  /// Inicializa o serviço de App Links
  /// Deve ser chamado no app_widget.dart após inicialização do Firebase
  Future<void> initialize(BuildContext context) async {
    _context = context;
    debugPrint('🔗 [AppLinksService] Inicializando serviço...');

    try {
      _appLinks = AppLinks();

      // Verificar se há um link inicial (app foi aberto via deep link)
      final Uri? initialLink = await _appLinks.getInitialLink();
      
      if (initialLink != null) {
        debugPrint('🔗 [AppLinksService] Link inicial encontrado: $initialLink');
        await _handleAppLink(initialLink);
      } else {
        debugPrint('🔗 [AppLinksService] Nenhum link inicial encontrado');
      }

      // Configurar listener para links recebidos enquanto o app está ativo
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) async {
          debugPrint('🔗 [AppLinksService] Link recebido: $uri');
          await _handleAppLink(uri);
        },
        onError: (error) {
          debugPrint('❌ [AppLinksService] Erro ao processar link: $error');
        },
      );

      debugPrint('✅ [AppLinksService] Serviço inicializado com sucesso!');
    } on MissingPluginException catch (e) {
      debugPrint('⚠️ [AppLinksService] Plugin não disponível (simulador?): $e');
      debugPrint('🔗 [AppLinksService] Deep links funcionarão apenas em dispositivos físicos');
    } catch (e) {
      debugPrint('❌ [AppLinksService] Erro na inicialização: $e');
    }
  }

  /// Processa um App Link recebido
  Future<void> _handleAppLink(Uri deepLink) async {
    debugPrint('🔗 [AppLinksService] Processando deep link: $deepLink');

    try {
      // Verificar se é um link de verificação de email
      if (_isEmailVerificationLink(deepLink)) {
        await _handleEmailVerificationLink(deepLink);
      } else if (_isEmailVerifiedLink(deepLink)) {
        await _handleEmailVerifiedLink(deepLink);
      } else if (_isHomeLink(deepLink)) {
        await _handleHomeLink(deepLink);
      } else if (_isAuthLink(deepLink)) {
        await _handleAuthLink(deepLink);
      } else if (_isBarLink(deepLink)) {
        await _handleBarLink(deepLink);
      } else if (_isEventLink(deepLink)) {
        await _handleEventLink(deepLink);
      } else {
        debugPrint('🔗 [AppLinksService] Link não reconhecido: $deepLink');
      }
    } catch (e) {
      debugPrint('❌ [AppLinksService] Erro ao processar deep link: $e');
    }
  }

  /// Verifica se o link é de verificação de email
  bool _isEmailVerificationLink(Uri link) {
    // Verificar se contém parâmetros de verificação de email
    final mode = link.queryParameters['mode'];
    final oobCode = link.queryParameters['oobCode'];
    
    return mode == 'verifyEmail' && oobCode != null && oobCode.isNotEmpty;
  }

  /// Verifica se o link contém o parâmetro emailVerified=true
  bool _isEmailVerifiedLink(Uri link) {
    final emailVerified = link.queryParameters['emailVerified'];
    return emailVerified == 'true';
  }

  /// Verifica se é um link de autenticação
  bool _isAuthLink(Uri link) {
    return link.path.startsWith('/auth/');
  }

  /// Verifica se é um link de bar
  bool _isBarLink(Uri link) {
    return link.path.startsWith('/bar/');
  }

  /// Verifica se é um link de evento
  bool _isEventLink(Uri link) {
    return link.path.startsWith('/event/');
  }

  /// Verifica se é um link para a home
  bool _isHomeLink(Uri link) {
    return link.path == '/home';
  }

  /// Processa link de verificação de email
  Future<void> _handleEmailVerificationLink(Uri link) async {
    debugPrint('📧 [AppLinksService] Processando link de verificação de email...');
    
    if (_context == null) {
      debugPrint('❌ [AppLinksService] Contexto não disponível para navegação');
      return;
    }

    try {
      // Extrair parâmetros do link
      final oobCode = link.queryParameters['oobCode'];
      final continueUrl = link.queryParameters['continueUrl'];
      
      debugPrint('📧 [AppLinksService] OobCode: $oobCode');
      debugPrint('📧 [AppLinksService] ContinueUrl: $continueUrl');

      // Navegar para /login com parâmetros de verificação
      if (_context!.mounted) {
        // Aguardar um pouco para garantir que o app está pronto
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Forçar atualização do estado de autenticação
        try {
          final authViewModel = _context!.read<AuthViewModel>();
          await authViewModel.refreshRegistrationStatus();
          debugPrint('✅ [AppLinksService] Estado de autenticação atualizado');
        } catch (e) {
          debugPrint('⚠️ [AppLinksService] Erro ao atualizar estado de auth: $e');
        }
        
        _context!.go('/login?emailVerified=true&fromDeepLink=true');
        
        // Mostrar feedback de sucesso
        _showEmailVerifiedSnackBar();
        
        debugPrint('✅ [AppLinksService] Navegação para /login realizada com sucesso!');
      }
    } catch (e) {
      debugPrint('❌ [AppLinksService] Erro ao processar verificação de email: $e');
    }
  }

  /// Processa link com parâmetro emailVerified=true (vindo da página HTML)
  Future<void> _handleEmailVerifiedLink(Uri link) async {
    debugPrint('✅ [AppLinksService] Processando link de email verificado...');
    
    if (_context == null) {
      debugPrint('❌ [AppLinksService] Contexto não disponível para navegação');
      return;
    }

    try {
      debugPrint('✅ [AppLinksService] Email verificado detectado via deep link');
      
      if (_context!.mounted) {
        // Aguardar um pouco para garantir que o app está pronto
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Forçar atualização do estado de autenticação
        try {
          final authViewModel = _context!.read<AuthViewModel>();
          await authViewModel.refreshRegistrationStatus();
          debugPrint('✅ [AppLinksService] Estado de autenticação atualizado');
        } catch (e) {
          debugPrint('⚠️ [AppLinksService] Erro ao atualizar estado de auth: $e');
        }
        
        // Navegar diretamente para a home, pois o usuário já verificou o email
        _context!.go('/home');
        
        // Mostrar feedback de sucesso
        _showEmailVerifiedSnackBar();
        
        debugPrint('✅ [AppLinksService] Navegação automática para /home realizada!');
      }
    } catch (e) {
      debugPrint('❌ [AppLinksService] Erro ao processar email verificado: $e');
    }
  }

  /// Processa links de autenticação
  Future<void> _handleAuthLink(Uri link) async {
    debugPrint('🔐 [AppLinksService] Processando link de autenticação: ${link.path}');
    
    if (_context == null || !_context!.mounted) return;

    try {
      // Navegar para a rota de autenticação correspondente
      _context!.go(link.path);
      debugPrint('✅ [AppLinksService] Navegação para ${link.path} realizada');
    } catch (e) {
      debugPrint('❌ [AppLinksService] Erro ao processar link de auth: $e');
    }
  }

  /// Processa links de bar
  Future<void> _handleBarLink(Uri link) async {
    debugPrint('🍺 [AppLinksService] Processando link de bar: ${link.path}');
    
    if (_context == null || !_context!.mounted) return;

    try {
      // Navegar para a rota de bar correspondente
      _context!.go(link.path);
      debugPrint('✅ [AppLinksService] Navegação para ${link.path} realizada');
    } catch (e) {
      debugPrint('❌ [AppLinksService] Erro ao processar link de bar: $e');
    }
  }

  /// Processa links de evento
  Future<void> _handleEventLink(Uri link) async {
    debugPrint('🎉 [AppLinksService] Processando link de evento: ${link.path}');
    
    if (_context == null || !_context!.mounted) return;

    try {
      // Navegar para a rota de evento correspondente
      _context!.go(link.path);
      debugPrint('✅ [AppLinksService] Navegação para ${link.path} realizada');
    } catch (e) {
      debugPrint('❌ [AppLinksService] Erro ao processar link de evento: $e');
    }
  }

  /// Processa link para a home
  Future<void> _handleHomeLink(Uri link) async {
    debugPrint('🏠 [AppLinksService] Processando link para home...');
    
    if (_context == null || !_context!.mounted) {
      debugPrint('❌ [AppLinksService] Contexto não disponível para navegação');
      return;
    }

    try {
      // Navegar para a home
      _context!.go('/home');
      debugPrint('✅ [AppLinksService] Navegação para home realizada');
    } catch (e) {
      debugPrint('❌ [AppLinksService] Erro ao processar link para home: $e');
    }
  }

  /// Exibe mensagem de sucesso da verificação de email
  void _showEmailVerifiedSnackBar() {
    if (_context == null || !_context!.mounted) return;

    ScaffoldMessenger.of(_context!).showSnackBar(
      const SnackBar(
        content: Text('✅ E-mail verificado com sucesso!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Atualiza o contexto (útil para mudanças de rota)
  void updateContext(BuildContext context) {
    _context = context;
  }

  /// Libera recursos do serviço
  void dispose() {
    debugPrint('🔗 [AppLinksService] Liberando recursos...');
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _context = null;
  }
}