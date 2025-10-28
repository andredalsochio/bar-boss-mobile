import 'package:flutter/material.dart';
import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';

class EmptyEventsState extends StatefulWidget {
  final VoidCallback onCreateEvent;

  const EmptyEventsState({
    super.key,
    required this.onCreateEvent,
  });

  @override
  State<EmptyEventsState> createState() => _EmptyEventsStateState();
}

class _EmptyEventsStateState extends State<EmptyEventsState>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _rotateController;
  
  late Animation<double> _pulseAnimation;
  Animation<Offset>? _slideAnimation; 
  late Animation<double> _rotateAnimation;
  Animation<double>? _scaleAnimation; 

  @override
  void initState() {
    super.initState();
    
    // Controlador para o efeito de pulso
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Controlador para o slide dos elementos
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Controlador para rotação sutil
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Animação de pulso para o ícone
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Animação de slide para entrada dos elementos
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Animação de rotação sutil
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    ));

    // Animação de escala para entrada
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Iniciar animações
    _startAnimations();
  }

  void _startAnimations() {
    // Slide inicial
    _slideController.forward();
    
    // Pulso contínuo após um delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
    
    // Rotação sutil contínua
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _rotateController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 80, // mantém conteúdo centralizado e evita overflow
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
          // Ícone animado com múltiplos efeitos
          SlideTransition(
            position: _slideAnimation ?? const AlwaysStoppedAnimation(Offset.zero),
            child: ScaleTransition(
              scale: _scaleAnimation ?? const AlwaysStoppedAnimation(1.0),
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseAnimation, _rotateAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Transform.rotate(
                      angle: _rotateAnimation.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                           gradient: RadialGradient(
                             colors: [
                               AppColors.primary(context).withOpacity(0.15),
                               AppColors.primary(context).withOpacity(0.05),
                               Colors.transparent,
                             ],
                           ),
                           borderRadius: BorderRadius.circular(70),
                         ),
                         child: Container(
                           margin: const EdgeInsets.all(20),
                           decoration: BoxDecoration(
                             color: AppColors.primary(context).withOpacity(0.1),
                             borderRadius: BorderRadius.circular(50),
                             border: Border.all(
                               color: AppColors.primary(context).withOpacity(0.2),
                               width: 2,
                             ),
                           ),
                           child: Icon(
                             Icons.calendar_month_outlined,
                             size: 50,
                             color: AppColors.primary(context),
                           ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Texto principal animado
          SlideTransition(
            position: _slideAnimation ?? const AlwaysStoppedAnimation(Offset.zero),
            child: FadeTransition(
              opacity: _scaleAnimation ?? const AlwaysStoppedAnimation(1.0),
              child: Column(
                children: [
                  Text(
                    'Nenhum evento por aqui! 🎉',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Que tal criar seu primeiro evento e\ncomeçar a movimentar seu bar?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Botão animado com hover effect
          SlideTransition(
            position: _slideAnimation ?? const AlwaysStoppedAnimation(Offset.zero),
            child: ScaleTransition(
              scale: _scaleAnimation ?? const AlwaysStoppedAnimation(1.0),
              child: _AnimatedButton(
                 onPressed: widget.onCreateEvent,
                 text: AppStrings.createFirstEventButton,
               ),
            ),
          ),
        ],
      ),
    ));
      },
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;

  const _AnimatedButton({
    required this.onPressed,
    required this.text,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _hoverAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                   BoxShadow(
                     color: Theme.of(context).colorScheme.primary.withOpacity(_isHovered ? 0.3 : 0.15),
                     blurRadius: _isHovered ? 12 : 8,
                     offset: const Offset(0, 4),
                   ),
                 ],
               ),
               child: ElevatedButton.icon(
                 onPressed: widget.onPressed,
                 icon: const Icon(Icons.add_circle_outline, size: 20),
                 label: Text(
                   widget.text,
                   style: const TextStyle(
                     fontWeight: FontWeight.w600,
                     fontSize: 16,
                   ),
                 ),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Theme.of(context).colorScheme.primary,
                   foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}