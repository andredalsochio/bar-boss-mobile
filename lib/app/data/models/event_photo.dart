import 'dart:io';
import 'dart:convert';

/// Modelo para representar uma foto de evento
/// Usado tanto para persistência local quanto para sincronização com Firebase
class EventPhoto {
  /// ID único da foto
  final String id;
  
  /// ID do evento ao qual a foto pertence
  final String eventId;
  
  /// Caminho local do arquivo
  final String localPath;
  
  /// URL de download do Firebase Storage
  final String? downloadUrl;
  
  /// Caminho no Firebase Storage
  final String? storagePath;
  
  /// Status do upload
  final EventPhotoUploadStatus uploadStatus;
  
  /// Progresso do upload (0-100)
  final int uploadProgress;
  
  /// Tamanho do arquivo em bytes
  final int fileSize;
  
  /// Tipo MIME do arquivo
  final String mimeType;
  
  /// Largura da imagem em pixels
  final int? width;
  
  /// Altura da imagem em pixels
  final int? height;
  
  /// Número de tentativas de upload
  final int retryCount;
  
  /// Timestamp da última tentativa de upload
  final DateTime? lastRetryAt;
  
  /// Timestamp de criação
  final DateTime createdAt;
  
  /// Timestamp de atualização
  final DateTime updatedAt;
  
  /// Metadados adicionais
  final Map<String, dynamic>? metadata;

  const EventPhoto({
    required this.id,
    required this.eventId,
    required this.localPath,
    this.downloadUrl,
    this.storagePath,
    this.uploadStatus = EventPhotoUploadStatus.pending,
    this.uploadProgress = 0,
    required this.fileSize,
    required this.mimeType,
    this.width,
    this.height,
    this.retryCount = 0,
    this.lastRetryAt,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Cria uma cópia com campos atualizados
  EventPhoto copyWith({
    String? id,
    String? eventId,
    String? localPath,
    String? downloadUrl,
    String? storagePath,
    EventPhotoUploadStatus? uploadStatus,
    int? uploadProgress,
    int? fileSize,
    String? mimeType,
    int? width,
    int? height,
    int? retryCount,
    DateTime? lastRetryAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return EventPhoto(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      localPath: localPath ?? this.localPath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      storagePath: storagePath ?? this.storagePath,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'localPath': localPath,
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'uploadStatus': uploadStatus.value,
      'uploadProgress': uploadProgress,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'width': width,
      'height': height,
      'retryCount': retryCount,
      'lastRetryAt': lastRetryAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata != null ? jsonEncode(metadata!) : null,
    };
  }

  /// Cria instância a partir de JSON
  factory EventPhoto.fromJson(Map<String, dynamic> json) {
    return EventPhoto(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      localPath: json['localPath'] as String,
      downloadUrl: json['downloadUrl'] as String?,
      storagePath: json['storagePath'] as String?,
      uploadStatus: EventPhotoUploadStatus.fromValue(json['uploadStatus'] as int? ?? 0),
      uploadProgress: json['uploadProgress'] as int? ?? 0,
      fileSize: json['fileSize'] as int,
      mimeType: json['mimeType'] as String,
      width: json['width'] as int?,
      height: json['height'] as int?,
      retryCount: json['retryCount'] as int? ?? 0,
      lastRetryAt: json['lastRetryAt'] != null 
          ? DateTime.parse(json['lastRetryAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] != null 
          ? jsonDecode(json['metadata'] as String) as Map<String, dynamic>
          : null,
    );
  }
}

/// Status do upload de uma foto
enum EventPhotoUploadStatus {
  /// Aguardando upload
  pending(0),
  
  /// Upload em progresso
  uploading(1),
  
  /// Upload concluído com sucesso
  completed(2),
  
  /// Erro no upload
  failed(3),
  
  /// Upload cancelado
  cancelled(4);

  const EventPhotoUploadStatus(this.value);
  
  final int value;
  
  /// Cria enum a partir do valor
  static EventPhotoUploadStatus fromValue(int value) {
    return EventPhotoUploadStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => EventPhotoUploadStatus.pending,
    );
  }
  
  /// Verifica se o upload está em progresso
  bool get isUploading => this == EventPhotoUploadStatus.uploading;
  
  /// Verifica se o upload foi concluído
  bool get isCompleted => this == EventPhotoUploadStatus.completed;
  
  /// Verifica se houve erro
  bool get isFailed => this == EventPhotoUploadStatus.failed;
  
  /// Verifica se pode tentar novamente
  bool get canRetry => this == EventPhotoUploadStatus.failed || this == EventPhotoUploadStatus.cancelled;
}

/// Extensões úteis para EventPhoto
extension EventPhotoExtensions on EventPhoto {
  /// Verifica se o arquivo existe localmente
  bool get fileExists => File(localPath).existsSync();
  
  /// Verifica se a foto está pronta para exibição
  bool get isReadyForDisplay => uploadStatus.isCompleted && downloadUrl != null;
  
  /// Verifica se precisa de upload
  bool get needsUpload => uploadStatus == EventPhotoUploadStatus.pending || 
                         uploadStatus == EventPhotoUploadStatus.failed;
  
  /// Retorna o tamanho formatado do arquivo
  String get formattedFileSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  
  /// Retorna as dimensões formatadas
  String? get formattedDimensions {
    if (width != null && height != null) {
      return '${width}x$height';
    }
    return null;
  }
  
  /// Cria uma nova instância marcando como falha
  EventPhoto markAsFailed() {
    return copyWith(
      uploadStatus: EventPhotoUploadStatus.failed,
      retryCount: retryCount + 1,
      lastRetryAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Cria uma nova instância marcando como concluído
  EventPhoto markAsCompleted({
    required String downloadUrl,
    required String storagePath,
  }) {
    return copyWith(
      uploadStatus: EventPhotoUploadStatus.completed,
      downloadUrl: downloadUrl,
      storagePath: storagePath,
      uploadProgress: 100,
      updatedAt: DateTime.now(),
    );
  }
  
  /// Atualiza o progresso do upload
  EventPhoto updateProgress(int progress) {
    return copyWith(
      uploadStatus: EventPhotoUploadStatus.uploading,
      uploadProgress: progress.clamp(0, 100),
      updatedAt: DateTime.now(),
    );
  }
}