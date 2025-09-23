import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';
import 'package:bar_boss_mobile/app/core/widgets/app_bar_widget.dart';
import 'package:bar_boss_mobile/app/core/widgets/loading_widget.dart';

import 'package:bar_boss_mobile/app/core/widgets/event_card_widget.dart';
import 'package:bar_boss_mobile/app/modules/events/models/event_model.dart';
import 'package:bar_boss_mobile/app/modules/events/viewmodels/events_viewmodel.dart';
import 'package:bar_boss_mobile/app/modules/home/viewmodels/home_viewmodel.dart';

/// Tela de listagem de eventos
class EventsListPage extends StatefulWidget {
  const EventsListPage({super.key});

  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage> {
  late final EventsViewModel _viewModel;
  late final HomeViewModel _homeViewModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<EventsViewModel>();
    _homeViewModel = context.read<HomeViewModel>();
    
    // Carrega os eventos após o build inicial para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _viewModel.loadEvents();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToEventDetails(EventModel event) {
    context.pushNamed(
      'eventDetails',
      pathParameters: {'id': event.id},
    );
  }

  void _goToEventEdit(EventModel event) {
    context.pushNamed(
      'eventEdit',
      pathParameters: {'id': event.id},
    );
  }

  void _goToNewEvent() {
    debugPrint('🎯 DEBUG EventsList: _goToNewEvent chamado');
    debugPrint('🎯 DEBUG EventsList: _homeViewModel.hasBar = ${_homeViewModel.hasBar}');
    debugPrint('🎯 DEBUG EventsList: _homeViewModel.userBars.length = ${_homeViewModel.userBars.length}');
    debugPrint('🎯 DEBUG EventsList: _homeViewModel.currentBar = ${_homeViewModel.currentBar?.id}');
    
    if (_homeViewModel.hasBar) {
      debugPrint('🎯 DEBUG EventsList: Navegando para criação de evento (hasBar=true)');
      context.pushNamed('eventForm');
    } else {
      debugPrint('🚫 DEBUG EventsList: Usuário sem bar - exibindo modal');
      _showNoBarModal();
    }
  }

  void _showNoBarModal() {
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
        title: AppStrings.eventsListTitle,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Atualizar eventos',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _goToNewEvent,
            tooltip: AppStrings.newEventTooltip,
          ),
        ],
      ),
      body: Consumer<EventsViewModel>(
        builder: (context, viewModel, _) {
          if (_isLoading) {
            return const LoadingWidget();
          }



          final events = viewModel.events;

          if (events.isEmpty) {
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),
                  ElevatedButton.icon(
                    onPressed: _goToNewEvent,
                    icon: const Icon(Icons.add),
                    label: Text(AppStrings.createFirstEventButton),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(context),
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.buttonHorizontalPadding,
                        vertical: AppSizes.buttonVerticalPadding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadEvents,
            color: AppColors.primary(context),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spacingMedium),
                  child: EventCardWidget(
                    event: event,
                    onViewDetails: () => _goToEventDetails(event),
                    onEdit: () => _goToEventEdit(event),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToNewEvent,
        backgroundColor: AppColors.primary(context),
        child: Icon(
          Icons.add,
          color: AppColors.white,
        ),
      ),
    );
  }
}