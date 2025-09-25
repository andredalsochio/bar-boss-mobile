import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';
import 'package:bar_boss_mobile/app/core/widgets/app_bar_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/button_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/loading_widget.dart';

import 'package:bar_boss_mobile/app/core/widgets/event_card_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/app_drawer.dart';
import 'package:bar_boss_mobile/app/core/widgets/profile_complete_card_widget.dart';
import 'package:bar_boss_mobile/app/modules/auth/viewmodels/auth_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/events/viewmodels/events_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/events/models/event_model.dart';
import 'package:bar_boss_mobile/app/modules/home/viewmodels/home_viewmodel.dart';

/// Tela inicial do aplicativo
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final EventsViewModel _eventsViewModel;
  late final AuthViewModel _authViewModel;
  late final HomeViewModel _homeViewModel;

  @override
  void initState() {
    super.initState();
    _eventsViewModel = context.read<EventsViewModel>();
    _authViewModel = context.read<AuthViewModel>();
    _homeViewModel = context.read<HomeViewModel>();
    
    // Carregamento assíncrono pós-frame otimizado para reduzir jank inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataOptimized();
    });
  }

  /// Carregamento otimizado com priorização para reduzir jank inicial
  Future<void> _loadDataOptimized() async {
    debugPrint('🏠 DEBUG HomePage: Iniciando carregamento otimizado...');
    
    try {
      // Fase 1: Carregamento crítico (UserProfile) - bloqueia UI mínimo
      debugPrint('🏠 DEBUG HomePage: Fase 1 - Carregando UserProfile (crítico)...');
      await _homeViewModel.loadUserProfile();
      
      // Aguarda próximo frame para evitar jank
      await Future.delayed(Duration.zero);
      
      // Fase 2: Carregamento paralelo de dados secundários
      debugPrint('🏠 DEBUG HomePage: Fase 2 - Carregando dados secundários em paralelo...');
      
      final futures = <Future<void>>[];
      
      // CurrentBar - importante mas não crítico
      futures.add(_loadCurrentBarAsync());
      
      // UpcomingEvents - pode ser carregado independentemente
      futures.add(_loadUpcomingEventsAsync());
      
      // Aguarda todos os carregamentos secundários
      await Future.wait(futures);
      
      debugPrint('🏠 DEBUG HomePage: Carregamento otimizado concluído com sucesso');
    } catch (e) {
      debugPrint('❌ DEBUG HomePage: Erro no carregamento otimizado: $e');
    }
  }

  /// Carrega CurrentBar de forma assíncrona com tratamento de erro isolado
  Future<void> _loadCurrentBarAsync() async {
    try {
      debugPrint('🏠 DEBUG HomePage: Carregando CurrentBar (assíncrono)...');
      await _homeViewModel.loadCurrentBar();
      debugPrint('🏠 DEBUG HomePage: CurrentBar carregado com sucesso');
    } catch (e) {
      debugPrint('❌ DEBUG HomePage: Erro ao carregar CurrentBar: $e');
      // Não propaga erro para não afetar outros carregamentos
    }
  }

  /// Carrega UpcomingEvents de forma assíncrona com tratamento de erro isolado
  Future<void> _loadUpcomingEventsAsync() async {
    try {
      debugPrint('🏠 DEBUG HomePage: Carregando UpcomingEvents (assíncrono)...');
      await _eventsViewModel.loadUpcomingEvents();
      debugPrint('🏠 DEBUG HomePage: UpcomingEvents carregados com sucesso');
    } catch (e) {
      debugPrint('❌ DEBUG HomePage: Erro ao carregar UpcomingEvents: $e');
      // Não propaga erro para não afetar outros carregamentos
    }
  }


  void _showNoBarModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bar não cadastrado'),
          content: const Text(
            'Para criar eventos, você precisa ter um bar cadastrado. '
            'Deseja completar o cadastro do seu bar agora?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/register/step1');
              },
              child: const Text('Cadastrar Bar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBarWidget(
        title: AppStrings.homeTitle,
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _authViewModel.logout(),
            tooltip: 'Sair',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Card de completude do perfil
          Consumer<HomeViewModel>(
            builder: (context, homeViewModel, _) {
              if (homeViewModel.shouldShowProfileCompleteCard) {
                return ProfileCompleteCardWidget(
                  completedSteps: homeViewModel.completedSteps,
                  totalSteps: homeViewModel.totalSteps,
                  onDismiss: () => homeViewModel.dismissProfileCompleteCard(),
                  onComplete: () => context.go('/register/step1'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Botões de ação
          Padding(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Row(
              children: [
                Expanded(
                  child: ButtonWidget(
                    text: AppStrings.scheduleButton,
                    onPressed: () => context.pushNamed('eventsList'),
                    icon: Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: AppSizes.spacingMedium),
                Expanded(
                  child: Consumer<HomeViewModel>(
                    builder: (context, viewModel, _) {
                      return ButtonWidget(
                        text: AppStrings.newEventButton,
                        onPressed: viewModel.hasBar 
                            ? () {
                                debugPrint('🎯 DEBUG Home: Navegando para criação de evento (hasBar=true)');
                                context.pushNamed('eventForm');
                              }
                            : () {
                                debugPrint('🚫 DEBUG Home: Usuário sem bar - exibindo modal');
                                _showNoBarModal(context);
                              },
                        icon: Icons.add_circle,
                        backgroundColor: AppColors.primary(context), // Sempre habilitado
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Título da seção
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPadding,
              vertical: AppSizes.spacingMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.nextEventLabel,
                  style: TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                TextButton(
                  onPressed: () => context.pushNamed('eventsList'),
                  child: Text(
                    AppStrings.manageScheduleLabel,
                    style: TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.primary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de próximos eventos
          Expanded(
            child: Consumer<EventsViewModel>(
              builder: (context, viewModel, _) {
                if (viewModel.isLoading) {
                  return const LoadingWidget();
                }



                if (viewModel.upcomingEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: AppSizes.iconSizeLarge,
                          color: AppColors.textSecondary(context),
                        ),
                        const SizedBox(height: AppSizes.spacingMedium),
                        Text(
                          AppStrings.noEventsMessage,
                          style: TextStyle(
                            fontSize: AppSizes.fontSizeMedium,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingLarge),
                        Consumer<HomeViewModel>(
                          builder: (context, homeViewModel, _) {
                            return ButtonWidget(
                              text: AppStrings.createFirstEventMessage,
                              onPressed: () {
                                debugPrint('🎯 DEBUG Home: Botão criar evento pressionado');
                                debugPrint('🎯 DEBUG Home: homeViewModel.hasBar = ${homeViewModel.hasBar}');
                                debugPrint('🎯 DEBUG Home: homeViewModel.userBars.length = ${homeViewModel.userBars.length}');
                                debugPrint('🎯 DEBUG Home: homeViewModel.currentBar = ${homeViewModel.currentBar?.id}');
                                
                                if (homeViewModel.hasBar) {
                                  debugPrint('🎯 DEBUG Home: Navegando para criação de evento (hasBar=true)');
                                  context.pushNamed('eventForm');
                                } else {
                                  debugPrint('🚫 DEBUG Home: Usuário sem bar - exibindo modal');
                                  _showNoBarModal(context);
                                }
                              },
                              icon: Icons.add_circle,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPadding,
                  ),
                  itemCount: viewModel.upcomingEvents.length,
                  itemBuilder: (context, index) {
                    final event = viewModel.upcomingEvents[index];
                    return _buildEventCard(event);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    return EventCardWidget(
      event: event,
      onViewDetails: () => context.pushNamed('eventDetails', pathParameters: {'id': event.id}),
      onEdit: () => context.pushNamed('eventEdit', pathParameters: {'id': event.id}),

    );
  }


}