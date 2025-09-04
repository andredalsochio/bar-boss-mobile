/// Classe que contém as strings utilizadas no aplicativo
class AppStrings {
  // Títulos de telas
  static const String appName = 'Agenda de Boteco';
  static const String loginTitle = 'Login';
  static const String registerStep1Title = 'Cadastro - Passo 1';
  static const String registerStep2Title = 'Cadastro - Passo 2';
  static const String registerStep3Title = 'Cadastro - Passo 3';
  static const String homeTitle = 'Painel do Bar';
  static const String eventsListTitle = 'Agenda';
  static const String eventFormTitle = 'Detalhes do Evento';
  static const String newEventTitle = 'Novo Evento';
  static const String editEventTitle = 'Editar Evento';
  
  // Botões
  static const String loginButton = 'Entrar';
  static const String registerButton = 'Cadastre-se';
  static const String forgotPasswordButton = 'Esqueci minha senha';
  static const String continueButton = 'Continuar';
  static const String submitButton = 'Enviar solicitação de cadastro';
  static const String submitRegistrationButton = 'Finalizar Cadastro';
  static const String saveButton = 'Salvar alterações';
  static const String saveChangesButton = 'Salvar alterações';
  static const String createEventButton = 'Criar evento';
  static const String deleteButton = 'Excluir';
  static const String cancelButton = 'Cancelar';
  static const String scheduleButton = 'Agenda';
  static const String newEventButton = 'Novo evento';
  static const String viewDetailsButton = 'Ver detalhes';
  static const String editEventButton = 'Editar evento';

  
  // Campos de formulário
  static const String emailField = 'E-mail para acesso';
  static const String emailHint = 'Digite seu e-mail';
  static const String emailLabel = 'E-mail';
  static const String passwordField = 'Senha';
  static const String createPasswordField = 'Criar senha';
  static const String confirmPasswordField = 'Confirmar senha';
  static const String confirmPasswordLabel = 'Confirmar Senha';
  static const String confirmPasswordHint = 'Digite novamente sua senha';
  static const String passwordLabel = 'Senha';
  static const String passwordHint = 'Digite sua senha';
  static const String registerBarStep3Title = 'Cadastro - Passo 3';
  static const String registerBarStep3Subtitle = 'Defina sua senha de acesso';
  static const String cnpjField = 'CNPJ';
  static const String cnpjLabel = 'CNPJ';
  static const String cnpjHint = 'Digite o CNPJ do estabelecimento';
  static const String barNameField = 'Nome comercial do bar';
  static const String barNameLabel = 'Nome do Bar';
  static const String barNameHint = 'Digite o nome comercial do bar';
  static const String responsibleNameField = 'Nome do responsável';
  static const String responsibleNameLabel = 'Nome do Responsável';
  static const String responsibleNameHint = 'Digite o nome do responsável';
  static const String phoneField = 'Telefone';
  static const String phoneLabel = 'Telefone';
  static const String phoneHint = 'Digite o telefone com DDD';
  
  // Mensagens de erro
  static const String userNotFoundErrorMessage = 'Usuário não encontrado';
  static const String loadEventsErrorMessage = 'Erro ao carregar eventos';
  static const String deleteEventErrorMessage = 'Erro ao excluir evento';
  static const String newEventTooltip = 'Novo evento';
  static const String createFirstEventButton = 'Criar primeiro evento';
  
  static const String cepField = 'CEP';
  static const String cepLabel = 'CEP';
  static const String cepHint = 'Digite o CEP';
  static const String registerBarStep1Title = 'Cadastro - Passo 1';
  static const String registerBarStep1Subtitle = 'Informações de contato';
  static const String registerBarStep2Title = 'Cadastro - Passo 2';
  static const String registerBarStep2Subtitle = 'Endereço do estabelecimento';
  static const String streetField = 'Rua';
  static const String streetLabel = 'Rua';
  static const String streetHint = 'Digite o nome da rua';
  static const String numberField = 'Número';
  static const String numberLabel = 'Número';
  static const String numberHint = 'Digite o número';
  static const String complementField = 'Complemento';
  static const String complementLabel = 'Complemento';
  static const String complementHint = 'Apartamento, sala, etc. (opcional)';
  static const String stateLabel = 'Estado';
  static const String stateHint = 'Selecione o estado';
  static const String cityLabel = 'Cidade';
  static const String cityHint = 'Digite a cidade';
  static const String stateField = 'Estado';
  static const String cityField = 'Cidade';
  static const String eventDateLabel = 'Data do evento';
  static const String attractionsLabel = 'Atrações';
  static const String attractionHint = 'Nome da atração';
  static const String promotionsLabel = 'Promoções';
  static const String promotionDetailsLabel = 'Detalhes da promoção';
  static const String promotionDetailsHint = 'Descreva as promoções do evento...';
  static const String promotionImagesPlaceholder = 'Adicione até 3 imagens de promoção';
  // Mensagens de erro
  static const String requiredField = 'Campo obrigatório';
  static const String requiredFieldError = 'Este campo é obrigatório';
  static const String invalidEmail = 'E-mail inválido';
  static const String invalidEmailError = 'E-mail inválido';
  static const String invalidCnpj = 'CNPJ inválido';
  static const String invalidCnpjError = 'CNPJ inválido';
  static const String invalidCep = 'CEP inválido';
  static const String invalidCepError = 'CEP inválido';
  static const String invalidPhone = 'Telefone inválido';
  static const String invalidPhoneError = 'Telefone inválido';
  static const String passwordTooShort = 'A senha deve ter pelo menos 6 caracteres';
  static const String passwordTooShortError = 'A senha deve ter pelo menos 6 caracteres';
  static const String passwordsDontMatch = 'As senhas não conferem';
  static const String passwordMismatchError = 'As senhas não coincidem';
  static const String emailInUseErrorMessage = 'Este e-mail já está em uso. Por favor, utilize outro e-mail.';
  static const String cnpjInUseErrorMessage = 'Este CNPJ já está cadastrado. Por favor, verifique os dados informados.';
  static const String loginError = 'Erro ao fazer login';
  static const String registrationError = 'Erro ao fazer cadastro';
  static const String networkError = 'Erro de conexão. Verifique sua internet';
  static const String unknownError = 'Erro desconhecido. Tente novamente';
  static const String invalidDateErrorMessage = 'Data inválida';
  static const String invalidAttractionsErrorMessage = 'Adicione pelo menos uma atração';
  
  // Mensagens de sucesso
  static const String registerSuccess = 'Cadastro realizado com sucesso!';
  static const String registrationSuccessMessage = 'Cadastro realizado com sucesso!';
  static const String eventCreatedSuccessMessage = 'Evento criado com sucesso!';
  static const String eventUpdatedSuccessMessage = 'Evento atualizado com sucesso!';
  static const String eventDeletedSuccessMessage = 'Evento excluído com sucesso!';
  
  // Outros
  static const String nextEventLabel = 'Próximo evento';
  static const String manageScheduleLabel = 'Gerenciar agenda';
  static const String additionalAttractionLabel = '+ Atração adicional';
  static const String selectDayLabel = 'Selecionar dia';
  static const String charactersCountLabel = '%d/100 caracteres';
  static const String imagesAddedLabel = '%d/3 imagens adicionadas';

  static const String noEventsMessage = 'Nenhum evento encontrado';
  static const String createFirstEventMessage = 'Crie seu primeiro evento';
  static const String deleteEventConfirmationTitle = 'Excluir evento';
  static const String deleteEventConfirmationMessage = 'Tem certeza que deseja excluir este evento? Esta ação não pode ser desfeita.';
  static const String deleteEventTooltip = 'Excluir evento';
  static const String addAttractionTooltip = 'Adicionar atração';
  static const String loadingMessage = 'Carregando...';
  static const String removeAttractionTooltip = 'Remover atração';
  static const String promotionsAvailable = 'Promoções disponíveis';

  static const String logoutErrorMessage = 'Erro ao fazer logout';
  static const String resetPasswordErrorMessage = 'Erro ao enviar email de redefinição de senha';
  static const String loginErrorMessage = 'Erro ao fazer login';
  static const String saveEventErrorMessage = 'Erro ao salvar evento';
  static const String userNotLoggedInErrorMessage = 'Usuário não está logado';
  static const String eventNotFoundErrorMessage = 'Evento não encontrado';
  static const String loadEventErrorMessage = 'Erro ao carregar evento';
  static const String formValidationErrorMessage = 'Por favor, preencha todos os campos obrigatórios';
  static const String dontHaveBarQuestion = 'Não tem um bar?';
  static const String loginSubtitle = 'Acesse sua conta para gerenciar seu bar';
  static const String orLoginWith = 'Ou entre com';
  
  // Constantes para widgets de erro
  static const String genericErrorMessage = 'Ocorreu um erro inesperado';
  static const String retryButton = 'Tentar novamente';
  static const String noDataMessage = 'Nenhum dado encontrado';
}