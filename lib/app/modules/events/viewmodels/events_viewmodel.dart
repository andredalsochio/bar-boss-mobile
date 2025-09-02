import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bar_boss_mobile/app/core/constants/app_strings.dart';
import 'package:bar_boss_mobile/app/domain/repositories/auth_repository.dart';
import 'package:bar_boss_mobile/app/domain/repositories/event_repository_domain.dart';
import 'package:bar_boss_mobile/app/domain/repositories/bar_repository_domain.dart';
import 'package:bar_boss_mobile/app/modules/events/models/event_model.dart';
import 'package:bar_boss_mobile/app/modules/register_bar/models/bar_model.dart';
import 'package:bar_boss_mobile/app/core/services/toast_service.dart';

/// Estados possíveis da operação de eventos
enum EventsState { initial, loading, success, error }

/// ViewModel para gerenciar eventos
class EventsViewModel extends ChangeNotifier {
  final EventRepositoryDomain _eventRepository;
  final BarRepositoryDomain _barRepository;
  final AuthRepository _authRepository;

  EventsState _state = EventsState.initial;
  String? _errorMessage;
  bool _isLoading = false;

  // Dados do evento atual
  EventModel? _currentEvent;
  DateTime? _eventDate;
  List<String> _attractions = [''];
  List<File> _promotionImages = [];
  String _promotionDetails = '';
  final ImagePicker _imagePicker = ImagePicker();


  // Lista de eventos
  List<EventModel> _events = [];
  List<EventModel> _upcomingEvents = [];

  // Streams
  Stream<List<EventModel>>? _eventsStream;
  Stream<List<BarModel>>? _barsStream;

  // Validação dos campos
  bool _isDateValid = false;
  bool _areAttractionsValid = false;

  EventsViewModel({
    required EventRepositoryDomain eventRepository,
    required BarRepositoryDomain barRepository,
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
  DateTime? get eventDate => _eventDate;

  /// Lista de atrações
  List<String> get attractions => _attractions;

  /// Lista de imagens de promoção
  List<File> get promotionImages => _promotionImages;

  /// Detalhes da promoção
  String get promotionDetails => _promotionDetails;



  /// Lista de todos os eventos
  List<EventModel> get events => _events;

  /// Lista de eventos futuros
  List<EventModel> get upcomingEvents => _upcomingEvents;

  /// Stream de eventos
  Stream<List<EventModel>>? get eventsStream => _eventsStream;

  /// Stream de bares
  Stream<List<BarModel>>? get barsStream => _barsStream;

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

      // Configura stream de bares do usuário
      _barsStream = _barRepository.listMyBars(currentUser.uid);
      
      // Escuta o primeiro bar disponível para configurar stream de eventos
      final barsSnapshot = await _barsStream!.first;
      
      debugPrint('🔍 DEBUG: Usuário ${currentUser.uid} tem ${barsSnapshot.length} bares');
      for (int i = 0; i < barsSnapshot.length; i++) {
        debugPrint('  Bar $i: ${barsSnapshot[i].id} - ${barsSnapshot[i].name}');
      }
      
      if (barsSnapshot.isEmpty) {
        debugPrint('❌ DEBUG: Nenhum bar encontrado para o usuário ${currentUser.uid}');
        _events = [];
        _upcomingEvents = [];
        _setState(EventsState.success);
        return;
      }
      
      final bar = barsSnapshot.first; // Assume que o usuário tem apenas um bar
      debugPrint('✅ DEBUG: Usando bar ${bar.id} - ${bar.name}');

      // Configura stream de eventos do bar
      _eventsStream = _eventRepository.upcomingByBar(bar.id);
      
      // Carrega eventos iniciais
      final eventsSnapshot = await _eventsStream!.first;
      _events = eventsSnapshot;
      _upcomingEvents = eventsSnapshot.where((event) => 
        event.startAt.isAfter(DateTime.now())
      ).toList();
      
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
    _eventDate = null;
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

      // Busca bares do usuário
      final barsSnapshot = await _barRepository.listMyBars(currentUser.uid).first;
      
      debugPrint('🔍 DEBUG loadEvent: Usuário ${currentUser.uid} tem ${barsSnapshot.length} bares');
      for (int i = 0; i < barsSnapshot.length; i++) {
        debugPrint('  Bar $i: ${barsSnapshot[i].id} - ${barsSnapshot[i].name}');
      }
      
      if (barsSnapshot.isEmpty) {
        debugPrint('❌ DEBUG loadEvent: Nenhum bar encontrado para o usuário ${currentUser.uid}');
        _setError(AppStrings.userNotFoundErrorMessage);
        return;
      }
      
      final bar = barsSnapshot.first; // Assume que o usuário tem apenas um bar
      debugPrint('✅ DEBUG loadEvent: Usando bar ${bar.id} - ${bar.name}');

      // Busca o evento específico no stream de eventos
      final eventsSnapshot = await _eventRepository.upcomingByBar(bar.id).first;
      final event = eventsSnapshot.firstWhere(
        (e) => e.id == eventId,
        orElse: () => throw Exception('Evento não encontrado'),
      );

      _currentEvent = event;
      _eventDate = event.startAt;
      _attractions = List<String>.from(event.attractions ?? []);
      _promotionDetails = event.description ?? '';

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

  /// Adiciona uma imagem de promoção da galeria
  Future<void> addPromotionImageFromGallery() async {
    if (_promotionImages.length >= 3) return;
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        _promotionImages.add(File(image.path));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao selecionar imagem da galeria: $e');
    }
  }
  
  /// Adiciona uma imagem de promoção da câmera
  Future<void> addPromotionImageFromCamera() async {
    if (_promotionImages.length >= 3) return;
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        _promotionImages.add(File(image.path));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao capturar imagem da câmera: $e');
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
    // A data deve ser no futuro e não pode ser null
    _isDateValid = _eventDate != null && _eventDate!.isAfter(DateTime.now());
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

      // Busca bares do usuário
      final barsSnapshot = await _barRepository.listMyBars(currentUser.uid).first;
      
      if (barsSnapshot.isEmpty) {
        _setError(AppStrings.userNotFoundErrorMessage);
        return;
      }
      
      final bar = barsSnapshot.first; // Assume que o usuário tem apenas um bar

      // Remove atrações vazias
      final filteredAttractions =
          _attractions.where((a) => a.trim().isNotEmpty).toList();

      if (_currentEvent == null) {
        // Cria um novo evento
        final eventStartDate = _eventDate ?? DateTime.now();
        final newEvent = EventModel(
          id: '',
          barId: bar.id,
          title: 'Evento', // Título padrão, pode ser editado posteriormente
          description: _promotionDetails.isNotEmpty ? _promotionDetails : '',
          startAt: eventStartDate,
          endAt: eventStartDate.add(const Duration(hours: 4)),
          attractions: filteredAttractions,
          coverImageUrl: '',
          published: false,
          createdByUid: currentUser.uid,
          updatedByUid: '',
          createdAt: DateTime.now(), // será sobrescrito pelo repositório
          updatedAt: DateTime.now(), // será sobrescrito pelo repositório
        );

        await _eventRepository.create(bar.id, newEvent);
      } else {
        // Atualiza o evento existente
        final eventStartDate = _eventDate ?? _currentEvent!.startAt;
        final updatedEvent = _currentEvent!.copyWith(
          startAt: eventStartDate,
          endAt: eventStartDate.add(const Duration(hours: 4)),
          attractions: filteredAttractions,
          description: _promotionDetails.isNotEmpty ? _promotionDetails : _currentEvent!.description,
          updatedByUid: currentUser.uid,
          updatedAt: DateTime.now(), // será sobrescrito pelo repositório
        );

        await _eventRepository.update(bar.id, updatedEvent);
      }

      // Define sucesso antes de recarregar eventos
      ToastService.instance.showSuccess(message: 'Evento salvo com sucesso!');
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
      final barsSnapshot = await _barRepository.listMyBars(currentUser.uid).first;
      
      if (barsSnapshot.isEmpty) {
        _events = [];
        _upcomingEvents = [];
        _setState(EventsState.success);
        return;
      }
      
      final bar = barsSnapshot.first; // Assume que o usuário tem apenas um bar

      // Carrega eventos futuros usando stream
      final eventsSnapshot = await _eventRepository.upcomingByBar(bar.id).first;
      _events = eventsSnapshot;
      _upcomingEvents = eventsSnapshot
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
      // Usa o barId do evento atual
      await _eventRepository.delete(_currentEvent!.barId, _currentEvent!.id);

      // Recarrega os eventos
      await loadEvents();

      ToastService.instance.showSuccess(message: 'Evento excluído com sucesso!');
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
    ToastService.instance.showError(message: message);
    notifyListeners();
  }

  /// Limpa a mensagem de erro
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
