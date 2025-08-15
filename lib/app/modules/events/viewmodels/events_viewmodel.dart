import 'package:flutter/material.dart';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/domain/repositories/auth_repository.dart';
import 'package:bar_boss_mobile/app/domain/repositories/event_repository.dart';
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository.dart';
import 'package:bar_boss_mobile/app/modules/events/models/event_model.dart';

/// Estados possíveis da operação de eventos
enum EventsState { initial, loading, success, error }

/// ViewModel para gerenciar eventos
class EventsViewModel extends ChangeNotifier {
  final EventRepository _eventRepository;
  final BarRepository _barRepository;
  final AuthRepository _authRepository;

  EventsState _state = EventsState.initial;
  String? _errorMessage;
  bool _isLoading = false;

  // Dados do evento atual
  EventModel? _currentEvent;
  DateTime _eventDate = DateTime.now();
  List<String> _attractions = [''];
  List<String> _promotionImages = [];
  String _promotionDetails = '';


  // Lista de eventos
  List<EventModel> _events = [];
  List<EventModel> _upcomingEvents = [];

  // Validação dos campos
  bool _isDateValid = false;
  bool _areAttractionsValid = false;

  EventsViewModel({
    required EventRepository eventRepository,
    required BarRepository barRepository,
    required AuthRepository authRepository,
  }) : _eventRepository = eventRepository,
       _barRepository = barRepository,
       _authRepository = authRepository;

  /// Estado atual da operação
  EventsState get state => _state;

  /// Mensagem de erro
  String? get errorMessage => _errorMessage;

  /// Indica se está carregando
  bool get isLoading => _isLoading;

  /// Evento atual sendo editado ou criado
  EventModel? get currentEvent => _currentEvent;

  /// Data do evento
  DateTime get eventDate => _eventDate;

  /// Lista de atrações
  List<String> get attractions => _attractions;

  /// Lista de imagens de promoção
  List<String> get promotionImages => _promotionImages;

  /// Detalhes da promoção
  String get promotionDetails => _promotionDetails;



  /// Lista de todos os eventos
  List<EventModel> get events => _events;

  /// Lista de eventos futuros
  List<EventModel> get upcomingEvents => _upcomingEvents;

  /// Validação da data
  bool get isDateValid => _isDateValid;

  /// Validação das atrações
  bool get areAttractionsValid => _areAttractionsValid;

  /// Verifica se o formulário está válido
  bool get isFormValid => _isDateValid && _areAttractionsValid;

  /// Inicializa o ViewModel carregando os eventos
  Future<void> init() async {
    await loadEvents();
  }

  /// Carrega todos os eventos do bar
  Future<void> loadEvents() async {
    _setLoading(true);
    _clearError();

    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        _setError(AppStrings.userNotLoggedInErrorMessage);
        return;
      }

      final bars = await _barRepository.listBarsByMembership(
        currentUser.uid,
      );
      
      debugPrint('🔍 DEBUG: Usuário ${currentUser.uid} tem ${bars.length} bares');
      for (int i = 0; i < bars.length; i++) {
        debugPrint('  Bar $i: ${bars[i].id} - ${bars[i].name}');
      }
      
      if (bars.isEmpty) {
        debugPrint('❌ DEBUG: Nenhum bar encontrado para o usuário ${currentUser.uid}');
        return;
      }
      
      final bar = bars.first; // Assume que o usuário tem apenas um bar
      debugPrint('✅ DEBUG: Usando bar ${bar.id} - ${bar.name}');

      _events = await _eventRepository.getEventsByBarId(bar.id);
      _upcomingEvents = await _eventRepository.getUpcomingEventsByBarId(bar.id);
      _setState(EventsState.success);
    } catch (e) {
      _setError(AppStrings.loadEventsErrorMessage);
      debugPrint('Erro ao carregar eventos: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Inicializa um novo evento
  void initNewEvent() {
    _currentEvent = null;
    _eventDate = DateTime.now();
    _attractions = [''];
    _promotionImages = [];
    _promotionDetails = '';


    _validateDate();
    _validateAttractions();

    notifyListeners();
  }

  /// Carrega um evento para edição
  Future<void> loadEvent(String eventId) async {
    _setLoading(true);
    _clearError();

    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        _setError(AppStrings.userNotLoggedInErrorMessage);
        return;
      }

      final bars = await _barRepository.listBarsByMembership(
        currentUser.uid,
      );
      
      debugPrint('🔍 DEBUG saveEvent: Usuário ${currentUser.uid} tem ${bars.length} bares');
      for (int i = 0; i < bars.length; i++) {
        debugPrint('  Bar $i: ${bars[i].id} - ${bars[i].name}');
      }
      
      if (bars.isEmpty) {
        debugPrint('❌ DEBUG saveEvent: Nenhum bar encontrado para o usuário ${currentUser.uid}');
        return;
      }
      
      final bar = bars.first; // Assume que o usuário tem apenas um bar
      debugPrint('✅ DEBUG saveEvent: Usando bar ${bar.id} - ${bar.name}');

      final event = await _eventRepository.getEventById(eventId);
      if (event == null) {
        _setError(AppStrings.eventNotFoundErrorMessage);
        return;
      }

      _currentEvent = event;
      _eventDate = event.startAt;
      _attractions = List<String>.from(event.attractions ?? []);
  

      _validateDate();
      _validateAttractions();

      _setState(EventsState.success);
    } catch (e) {
      _setError(AppStrings.loadEventErrorMessage);
      debugPrint('Erro ao carregar evento: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Define a data do evento
  void setEventDate(DateTime date) {
    _eventDate = date;
    _validateDate();
    notifyListeners();
  }

  /// Adiciona uma nova atração vazia
  void addAttraction() {
    _attractions.add('');
    _validateAttractions();
    notifyListeners();
  }

  /// Remove uma atração pelo índice
  void removeAttraction(int index) {
    if (_attractions.length > 1 && index >= 0 && index < _attractions.length) {
      _attractions.removeAt(index);
      _validateAttractions();
      notifyListeners();
    }
  }

  /// Atualiza uma atração pelo índice
  void updateAttraction(int index, String value) {
    if (index >= 0 && index < _attractions.length) {
      _attractions[index] = value.trim();
      _validateAttractions();
      notifyListeners();
    }
  }

  /// Adiciona uma imagem de promoção
  void addPromotionImage(String imagePath) {
    if (_promotionImages.length < 3) {
      _promotionImages.add(imagePath);
      notifyListeners();
    }
  }

  /// Remove uma imagem de promoção pelo índice
  void removePromotionImage(int index) {
    if (index >= 0 && index < _promotionImages.length) {
      _promotionImages.removeAt(index);
      notifyListeners();
    }
  }

  /// Define os detalhes da promoção
  void setPromotionDetails(String details) {
    _promotionDetails = details.trim();
    notifyListeners();
  }



  /// Valida a data do evento
  void _validateDate() {
    // A data deve ser no futuro
    _isDateValid = _eventDate.isAfter(DateTime.now());
  }

  /// Valida as atrações
  void _validateAttractions() {
    // Deve ter pelo menos uma atração não vazia
    _areAttractionsValid = _attractions.any(
      (attraction) => attraction.trim().isNotEmpty,
    );
  }

  /// Salva o evento (cria ou atualiza)
  Future<void> saveEvent() async {
    if (!isFormValid) {
      _setError(AppStrings.formValidationErrorMessage);
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        _setError(AppStrings.userNotLoggedInErrorMessage);
        return;
      }

      final bars = await _barRepository.listBarsByMembership(
        currentUser.uid,
      );
      
      if (bars.isEmpty) {
        return;
      }
      
      final bar = bars.first; // Assume que o usuário tem apenas um bar

      // Remove atrações vazias
      final filteredAttractions =
          _attractions.where((a) => a.trim().isNotEmpty).toList();

      if (_currentEvent == null) {
        // Cria um novo evento
        final newEvent = EventModel(
          id: '',
          barId: bar.id,
          title: filteredAttractions.isNotEmpty ? filteredAttractions.first : 'Evento',
          description: '',
          startAt: _eventDate,
          endAt: _eventDate.add(const Duration(hours: 4)),
          attractions: filteredAttractions,
          coverImageUrl: '',
          published: false,
          createdByUid: '',
          updatedByUid: '',
          createdAt: DateTime.now(), // será sobrescrito pelo repositório
          updatedAt: DateTime.now(), // será sobrescrito pelo repositório
        );

        await _eventRepository.createEvent(newEvent);
      } else {
        // Atualiza o evento existente
        final updatedEvent = _currentEvent!.copyWith(
          startAt: _eventDate,
          endAt: _eventDate.add(const Duration(hours: 4)),
          attractions: filteredAttractions,
          updatedAt: DateTime.now(), // será sobrescrito pelo repositório
        );

        await _eventRepository.updateEvent(updatedEvent);
      }

      // Define sucesso antes de recarregar eventos
      _setState(EventsState.success);
      
      // Recarrega os eventos em background (não afeta o estado de sucesso)
      try {
        await loadEvents();
      } catch (e) {
        // Log do erro mas não altera o estado de sucesso do salvamento
        debugPrint('Erro ao recarregar eventos após salvar: $e');
      }
    } catch (e) {
      _setError(AppStrings.saveEventErrorMessage);
      debugPrint('Erro ao salvar evento: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carrega os próximos eventos
  Future<void> loadUpcomingEvents() async {
    _setLoading(true);
    _clearError();

    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        _setError(AppStrings.userNotFoundErrorMessage);
        return;
      }

      // Busca os bares do usuário usando membership
      final bars = await _barRepository.listBarsByMembership(
        currentUser.uid,
      );
      
      if (bars.isEmpty) {
        return;
      }
      
      final bar = bars.first; // Assume que o usuário tem apenas um bar

      // Carrega eventos futuros
      final now = DateTime.now();
      final allEvents = await _eventRepository.getEventsByBarId(bar.id);
      _upcomingEvents =
          allEvents.where((event) => event.startAt.isAfter(now)).toList()
            ..sort((a, b) => a.startAt.compareTo(b.startAt));

      _setState(EventsState.success);
    } catch (e) {
      _setError(AppStrings.loadEventsErrorMessage);
      debugPrint('Erro ao carregar próximos eventos: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Exclui o evento atual
  Future<void> deleteEvent() async {
    if (_currentEvent == null) return;

    _setLoading(true);
    _clearError();

    try {
      await _eventRepository.deleteEvent(_currentEvent!.id);

      // Recarrega os eventos
      await loadEvents();

      _setState(EventsState.success);
    } catch (e) {
      _setError(AppStrings.deleteEventErrorMessage);
      debugPrint('Erro ao excluir evento: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Define o estado de carregamento
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Define o estado da operação
  void _setState(EventsState state) {
    _state = state;
    notifyListeners();
  }

  /// Define a mensagem de erro
  void _setError(String message) {
    _errorMessage = message;
    _state = EventsState.error;
    notifyListeners();
  }

  /// Limpa a mensagem de erro
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
