import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
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

  /// Lista de imagens de promoção (novas imagens locais)
  List<File> get promotionImages => _promotionImages;

  /// Lista de URLs das imagens existentes do evento
  List<String> get existingPromotionImages => _currentEvent?.promoImages ?? [];

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
      _promotionDetails = event.promoDetails ?? '';
      
      // Limpa as imagens locais pois estamos carregando um evento existente
      // As imagens existentes estão nas URLs do evento (promoImages)
      _promotionImages = [];
      
      debugPrint('✅ DEBUG loadEvent: Evento carregado - Data: ${event.startAt}, Atrações: ${event.attractions?.length ?? 0}, Imagens: ${event.promoImages?.length ?? 0}, Detalhes: ${event.promoDetails?.isNotEmpty == true ? "Sim" : "Não"}');

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

  /// Carrega um evento pelo ID (alias para loadEvent)
  Future<void> loadEventById(String eventId) async {
    await loadEvent(eventId);
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
      _attractions[index] = value;
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

  /// Remove uma imagem de promoção pelo índice (novas imagens)
  void removePromotionImage(int index) {
    if (index >= 0 && index < _promotionImages.length) {
      _promotionImages.removeAt(index);
      notifyListeners();
    }
  }

  /// Remove uma imagem existente do evento pelo índice
  void removeExistingPromotionImage(int index) {
    if (_currentEvent != null && index >= 0 && index < (_currentEvent!.promoImages?.length ?? 0)) {
      final updatedImages = List<String>.from(_currentEvent!.promoImages ?? []);
      updatedImages.removeAt(index);
      _currentEvent = _currentEvent!.copyWith(promoImages: updatedImages.isEmpty ? null : updatedImages);
      notifyListeners();
    }
  }

  /// Define os detalhes da promoção
  void setPromotionDetails(String details) {
    _promotionDetails = details.trim();
    notifyListeners();
  }

  /// Faz upload de uma imagem para o Firebase Storage
  Future<String?> _uploadImageToStorage(File imageFile, String eventId) async {
    try {
      // Verifica se o Firebase Storage está disponível
      final storage = FirebaseStorage.instance;
      
      // Debug: Verifica se o usuário está autenticado
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ [EventsViewModel] Usuário não autenticado para upload');
        return null;
      }
      debugPrint('✅ [EventsViewModel] Usuário autenticado: ${user.uid}');
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final storageRef = storage
          .ref()
          .child('events')
          .child(eventId)
          .child('images')
          .child(fileName);
      
      debugPrint('📸 [EventsViewModel] Iniciando upload da imagem: $fileName');
      
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('✅ [EventsViewModel] Imagem enviada com sucesso: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('❌ [EventsViewModel] Erro do Firebase ao enviar imagem: ${e.code} - ${e.message}');
      if (e.code == 'storage/object-not-found') {
        debugPrint('💡 [EventsViewModel] Firebase Storage pode não estar configurado');
      }
      return null;
    } catch (e) {
      debugPrint('❌ [EventsViewModel] Erro geral ao enviar imagem: $e');
      return null;
    }
  }

  /// Faz upload de todas as imagens de promoção
  Future<List<String>> _uploadPromotionImages(String eventId) async {
    final uploadedUrls = <String>[];
    
    for (final imageFile in _promotionImages) {
      final url = await _uploadImageToStorage(imageFile, eventId);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    
    debugPrint('📸 [EventsViewModel] ${uploadedUrls.length}/${_promotionImages.length} imagens enviadas');
    return uploadedUrls;
  }

  /// Valida a data do evento
  void _validateDate() {
    // A data deve ser hoje ou no futuro e não pode ser null
    if (_eventDate == null) {
      _isDateValid = false;
      return;
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(_eventDate!.year, _eventDate!.month, _eventDate!.day);
    
    _isDateValid = eventDay.isAtSameMomentAs(today) || eventDay.isAfter(today);
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
    debugPrint('💾 [EventsViewModel] Iniciando salvamento de evento...');
    if (!isFormValid) {
      debugPrint('❌ [EventsViewModel] Formulário inválido - cancelando salvamento');
      _setError(AppStrings.formValidationErrorMessage);
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [EventsViewModel] Usuário não autenticado');
        _setError(AppStrings.userNotLoggedInErrorMessage);
        return;
      }
      debugPrint('💾 [EventsViewModel] Usuário autenticado: ${currentUser.email}');

      // Busca bares do usuário
      debugPrint('💾 [EventsViewModel] Buscando bares do usuário...');
      final barsSnapshot = await _barRepository.listMyBars(currentUser.uid).first;
      
      if (barsSnapshot.isEmpty) {
        debugPrint('❌ [EventsViewModel] Nenhum bar encontrado para o usuário');
        _setError(AppStrings.userNotFoundErrorMessage);
        return;
      }
      
      final bar = barsSnapshot.first; // Assume que o usuário tem apenas um bar
      debugPrint('💾 [EventsViewModel] Usando bar: ${bar.id} - ${bar.name}');

      // Remove atrações vazias
      final filteredAttractions =
          _attractions.where((a) => a.trim().isNotEmpty).toList();
      debugPrint('💾 [EventsViewModel] Atrações filtradas: ${filteredAttractions.length} itens');

      String eventId;
      List<String> uploadedImageUrls = [];

      if (_currentEvent == null) {
        // Cria um novo evento
        debugPrint('➕ [EventsViewModel] Criando novo evento...');
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
        debugPrint('➕ [EventsViewModel] Dados do novo evento: data=$eventStartDate, atrações=${filteredAttractions.length}');

        eventId = await _eventRepository.create(bar.id, newEvent);
        debugPrint('✅ [EventsViewModel] Novo evento criado com sucesso! ID: $eventId');
        
        // Faz upload das imagens se houver
        if (_promotionImages.isNotEmpty) {
          debugPrint('📸 [EventsViewModel] Fazendo upload de ${_promotionImages.length} imagens...');
          try {
            uploadedImageUrls = await _uploadPromotionImages(eventId);
            
            // Atualiza o evento com as URLs das imagens
            if (uploadedImageUrls.isNotEmpty) {
              final eventWithImages = newEvent.copyWith(
                id: eventId,
                promoImages: uploadedImageUrls,
                promoDetails: _promotionDetails,
              );
              await _eventRepository.update(bar.id, eventWithImages);
              debugPrint('✅ [EventsViewModel] Evento atualizado com imagens!');
            } else {
              debugPrint('⚠️ [EventsViewModel] Nenhuma imagem foi enviada com sucesso, mas evento foi criado');
            }
          } catch (e) {
            debugPrint('⚠️ [EventsViewModel] Erro no upload de imagens, mas evento foi criado: $e');
          }
        }
      } else {
        // Atualiza o evento existente
        debugPrint('📝 [EventsViewModel] Atualizando evento existente: ${_currentEvent!.id}');
        eventId = _currentEvent!.id;
        final eventStartDate = _eventDate ?? _currentEvent!.startAt;
        
        // Faz upload das novas imagens se houver
        if (_promotionImages.isNotEmpty) {
          debugPrint('📸 [EventsViewModel] Fazendo upload de ${_promotionImages.length} imagens...');
          try {
            uploadedImageUrls = await _uploadPromotionImages(eventId);
          } catch (e) {
            debugPrint('⚠️ [EventsViewModel] Erro no upload de imagens durante atualização: $e');
            uploadedImageUrls = []; // Continua sem as novas imagens
          }
        }
        
        // Combina URLs existentes com as novas
        final existingImages = _currentEvent!.promoImages ?? [];
        final allImageUrls = [...existingImages, ...uploadedImageUrls];
        
        final updatedEvent = _currentEvent!.copyWith(
          startAt: eventStartDate,
          endAt: eventStartDate.add(const Duration(hours: 4)),
          attractions: filteredAttractions,
          description: _promotionDetails.isNotEmpty ? _promotionDetails : _currentEvent!.description,
          promoImages: allImageUrls.isNotEmpty ? allImageUrls : null,
          promoDetails: _promotionDetails.isNotEmpty ? _promotionDetails : _currentEvent!.promoDetails,
          updatedByUid: currentUser.uid,
          updatedAt: DateTime.now(), // será sobrescrito pelo repositório
        );
        debugPrint('📝 [EventsViewModel] Dados atualizados: data=$eventStartDate, atrações=${filteredAttractions.length}, imagens=${allImageUrls.length}');

        await _eventRepository.update(bar.id, updatedEvent);
        debugPrint('✅ [EventsViewModel] Evento atualizado com sucesso!');
      }

      // Define sucesso antes de recarregar eventos
      debugPrint('🎉 [EventsViewModel] Salvamento concluído com sucesso!');
      ToastService.instance.showSuccess(message: 'Evento salvo com sucesso!');
      _setState(EventsState.success);
      
      // Recarrega os eventos em background (não afeta o estado de sucesso)
      debugPrint('🔄 [EventsViewModel] Recarregando eventos em background...');
      try {
        await loadEvents();
        debugPrint('✅ [EventsViewModel] Eventos recarregados com sucesso!');
      } catch (e) {
        // Log do erro mas não altera o estado de sucesso do salvamento
        debugPrint('⚠️ [EventsViewModel] Erro ao recarregar eventos após salvar: $e');
      }
    } catch (e) {
      debugPrint('❌ [EventsViewModel] Erro ao salvar evento: $e');
      _setError(AppStrings.saveEventErrorMessage);
    } finally {
      _setLoading(false);
      debugPrint('🏁 [EventsViewModel] Finalizando processo de salvamento');
    }
  }

  /// Carrega os próximos eventos
  Future<void> loadUpcomingEvents() async {
    debugPrint('📅 [EventsViewModel] Iniciando carregamento de próximos eventos...');
    _setLoading(true);
    _clearError();

    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [EventsViewModel] Usuário não autenticado');
        _setError(AppStrings.userNotFoundErrorMessage);
        return;
      }
      debugPrint('👤 [EventsViewModel] Usuário autenticado: ${currentUser.uid}');

      // Busca os bares do usuário usando membership
      debugPrint('🏪 [EventsViewModel] Buscando bares do usuário...');
      final barsSnapshot = await _barRepository.listMyBars(currentUser.uid).first;
      debugPrint('🏪 [EventsViewModel] Encontrados ${barsSnapshot.length} bares');
      
      if (barsSnapshot.isEmpty) {
        debugPrint('⚠️ [EventsViewModel] Usuário não possui bares associados');
        _events = [];
        _upcomingEvents = [];
        _setState(EventsState.success);
        return;
      }
      
      final bar = barsSnapshot.first; // Assume que o usuário tem apenas um bar
      debugPrint('🏪 [EventsViewModel] Usando bar: ${bar.id} - ${bar.name}');

      // Carrega eventos futuros usando stream
      debugPrint('📅 [EventsViewModel] Buscando próximos eventos do bar...');
      final eventsSnapshot = await _eventRepository.upcomingByBar(bar.id).first;
      debugPrint('📅 [EventsViewModel] Encontrados ${eventsSnapshot.length} próximos eventos');
      _events = eventsSnapshot;
      _upcomingEvents = eventsSnapshot
            ..sort((a, b) => a.startAt.compareTo(b.startAt));
      debugPrint('📅 [EventsViewModel] Eventos ordenados por data');

      _setState(EventsState.success);
      debugPrint('✅ [EventsViewModel] Próximos eventos carregados com sucesso!');
    } catch (e) {
      debugPrint('❌ [EventsViewModel] Erro ao carregar próximos eventos: $e');
      _setError(AppStrings.loadEventsErrorMessage);
    } finally {
      _setLoading(false);
    }
  }

  /// Exclui o evento atual
  Future<void> deleteEvent() async {
    if (_currentEvent == null) {
      debugPrint('⚠️ [EventsViewModel] Tentativa de excluir evento nulo');
      return;
    }

    debugPrint('🗑️ [EventsViewModel] Iniciando exclusão do evento: ${_currentEvent!.id}');
    _setLoading(true);
    _clearError();

    try {
      // Usa o barId do evento atual
      debugPrint('🗑️ [EventsViewModel] Excluindo evento do bar: ${_currentEvent!.barId}');
      await _eventRepository.delete(_currentEvent!.barId, _currentEvent!.id);
      debugPrint('✅ [EventsViewModel] Evento excluído do repositório');

      // Recarrega os eventos
      debugPrint('🔄 [EventsViewModel] Recarregando eventos após exclusão...');
      await loadEvents();
      debugPrint('✅ [EventsViewModel] Eventos recarregados após exclusão');

      ToastService.instance.showSuccess(message: 'Evento excluído com sucesso!');
      _setState(EventsState.success);
      debugPrint('🎉 [EventsViewModel] Exclusão concluída com sucesso!');
    } catch (e) {
      debugPrint('❌ [EventsViewModel] Erro ao excluir evento: $e');
      _setError(AppStrings.deleteEventErrorMessage);
    } finally {
      _setLoading(false);
      debugPrint('🏁 [EventsViewModel] Finalizando processo de exclusão');
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
