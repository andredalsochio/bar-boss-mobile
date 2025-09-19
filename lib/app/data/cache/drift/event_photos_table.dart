import 'package:drift/drift.dart';

/// Status de upload da foto do evento
enum EventPhotoUploadStatus {
  pending(0),
  uploading(1),
  completed(2),
  failed(3);

  const EventPhotoUploadStatus(this.value);
  final int value;

  static EventPhotoUploadStatus fromValue(int value) {
    return EventPhotoUploadStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => EventPhotoUploadStatus.pending,
    );
  }
}

/// Tabela Drift para persistência local de fotos de eventos
/// Armazena metadados e status de upload das imagens
@DataClassName('EventPhotoData')
class EventPhotos extends Table {
  /// ID único da foto (UUID)
  TextColumn get id => text().withLength(min: 36, max: 36)();
  
  /// ID do evento associado
  TextColumn get eventId => text().withLength(min: 1, max: 100)();
  
  /// Caminho local do arquivo
  TextColumn get localPath => text()();
  
  /// URL de download do Firebase Storage (após upload)
  TextColumn get downloadUrl => text().nullable()();
  
  /// Caminho no Firebase Storage
  TextColumn get storagePath => text().nullable()();
  
  /// Status do upload
  IntColumn get uploadStatus => integer().withDefault(const Constant(0))();
  
  /// Progresso do upload (0-100)
  RealColumn get uploadProgress => real().withDefault(const Constant(0.0))();
  
  /// Tamanho do arquivo em bytes
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  
  /// Tipo MIME do arquivo
  TextColumn get mimeType => text().withDefault(const Constant('image/jpeg'))();
  
  /// Largura da imagem em pixels
  IntColumn get width => integer().nullable()();
  
  /// Altura da imagem em pixels
  IntColumn get height => integer().nullable()();
  
  /// Número de tentativas de upload
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  
  /// Data da última tentativa de upload
  DateTimeColumn get lastRetryAt => dateTime().nullable()();
  
  /// Data de criação
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Data de atualização
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Metadados adicionais (JSON)
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {localPath}, // Caminho local deve ser único
  ];
}