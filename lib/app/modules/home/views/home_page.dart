import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';
import 'package:bar_boss_mobile/app/core/widgets/app_bar_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/button_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/loading_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/error_message_widget.dart';
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
    
    // Carrega os dados após o build inicial para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _eventsViewModel.loadUpcomingEvents(),
      _homeViewModel.loadCurrentBar(),
    ]);
  }

  Future<void> _loadUpcomingEvents() async {
    await _eventsViewModel.loadUpcomingEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                  totalSteps: 2,
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
                        onPressed: viewModel.canCreateEvent 
                            ? () {
                                debugPrint('🎯 DEBUG Home: Navegando para criação de evento (canCreateEvent=true)');
                                context.pushNamed('eventForm');
                              }
                            : () {
                                debugPrint('🚫 DEBUG Home: Botão "Novo evento" desabilitado (canCreateEvent=false, motivo: ${viewModel.hasBar ? "perfil incompleto (${viewModel.profileStepsDone}/2)" : "nenhum bar cadastrado"})');
                              },
                        icon: Icons.add_circle,
                        backgroundColor: viewModel.canCreateEvent 
                            ? AppColors.primary 
                            : Colors.grey,
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
                  style: const TextStyle(
                    fontSize: AppSizes.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.pushNamed('eventsList'),
                  child: Text(
                    AppStrings.manageScheduleLabel,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSizeSmall,
                      color: AppColors.primary,
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

                if (viewModel.state == EventsState.error) {
                  return ErrorMessageWidget(
                    message: viewModel.errorMessage ?? 'Erro ao carregar eventos',
                    onRetry: _loadUpcomingEvents,
                  );
                }

                if (viewModel.upcomingEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_busy,
                          size: AppSizes.iconSizeLarge,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppSizes.spacingMedium),
                        Text(
                          AppStrings.noEventsMessage,
                          style: const TextStyle(
                            fontSize: AppSizes.fontSizeMedium,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingLarge),
                        ButtonWidget(
                          text: AppStrings.createFirstEventMessage,
                          onPressed: () => context.pushNamed('eventForm'),
                          icon: Icons.add_circle,
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