import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../drift/cache_database.dart';

/// Tipos de operação na fila de escrita
enum WriteOperationType {
  create,
  update,
  delete,
}

// Status das operações é controlado pelo campo 'completed' da tabela

/// Configuração da fila de escrita
class WriteQueueConfig {
  final int maxRetries;
  final Duration initialRetryDelay;
  final double backoffMultiplier;
  final Duration maxRetryDelay;
  final int batchSize;
  final Duration processingInterval;
  final bool enableBatching;

  const WriteQueueConfig({
    this.maxRetries = 5,
    this.initialRetryDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxRetryDelay = const Duration(minutes: 5),
    this.batchSize = 10,
    this.processingInterval = const Duration(seconds: 5),
    this.enableBatching = true,
  });
}

/// Resultado de processamento de uma operação
class WriteOperationResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? responseData;
  final DateTime timestamp;

  const WriteOperationResult({
    required this.success,
    this.error,
    this.responseData,
    required this.timestamp,
  });
}

/// Callback para executar operações remotas
typedef RemoteWriteCallback = Future<WriteOperationResult> Function(
  WriteOperationType type,
  String entityType,
  String entityId,
  Map<String, dynamic> data,
);

/// Serviço de fila de escrita com retry exponential backoff
class WriteQueueService {
  final CacheDatabase _database;
  final WriteQueueConfig _config;
  final Map<String, RemoteWriteCallback> _callbacks = {};
  
  Timer? _processingTimer;
  bool _isProcessing = false;
  final StreamController<WriteOperationResult> _resultController = 
      StreamController<WriteOperationResult>.broadcast();

  WriteQueueService({
    required CacheDatabase database,
    WriteQueueConfig? config,
  }) : _database = database,
       _config = config ?? const WriteQueueConfig();

  /// Stream de resultados das operações
  Stream<WriteOperationResult> get results => _resultController.stream;

  /// Registra callback para um tipo de entidade
  void registerCallback(String entityType, RemoteWriteCallback callback) {
    _callbacks[entityType] = callback;
  }

  /// Inicia o processamento da fila
  void startProcessing() {
    if (_processingTimer != null) return;
    
    _processingTimer = Timer.periodic(
      _config.processingInterval,
      (_) => _processQueue(),
    );
  }

  /// Para o processamento da fila
  void stopProcessing() {
    _processingTimer?.cancel();
    _processingTimer = null;
  }

  /// Adiciona operação à fila
  Future<String> enqueue({
    required WriteOperationType type,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    Map<String, dynamic>? metadata,
  }) async {
    final operationId = _generateOperationId();
    final now = DateTime.now();

    await _database.into(_database.syncQueue).insert(
      SyncQueueCompanion(
        id: Value(operationId),
        entityType: Value(entityType),
        entityId: Value(entityId),
        operation: Value(type.name),
        data: Value(jsonEncode(data)),
        retryCount: const Value(0),
        createdAt: Value(now),
        nextAttemptAt: Value(now),
        completed: const Value(false),
      ),
    );

    return operationId;
  }

  /// Remove operação da fila
  Future<void> cancel(String operationId) async {
    await (_database.delete(_database.syncQueue)
      ..where((tbl) => tbl.id.equals(operationId))).go();
  }

  /// Processa a fila de operações
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final pendingOperations = await _getPendingOperations();
      
      if (pendingOperations.isEmpty) return;

      if (_config.enableBatching) {
        await _processBatch(pendingOperations);
      } else {
        for (final operation in pendingOperations) {
          await _processOperation(operation);
        }
      }
    } catch (e) {
      // TODO: Implementar logging framework
      // Logger.error('Erro ao processar fila: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Busca operações pendentes
  Future<List<SyncQueueData>> _getPendingOperations() async {
    final now = DateTime.now();
    
    final query = _database.select(_database.syncQueue)
      ..where((tbl) => 
          tbl.completed.equals(false) &
          tbl.nextAttemptAt.isSmallerOrEqualValue(now))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)])
      ..limit(_config.batchSize);

    return query.get();
  }

  /// Processa operações em lote
  Future<void> _processBatch(List<SyncQueueData> operations) async {
    // Agrupa por tipo de entidade para otimizar
    final groupedOps = <String, List<SyncQueueData>>{};
    
    for (final op in operations) {
      groupedOps.putIfAbsent(op.entityType, () => []).add(op);
    }

    // Processa cada grupo
    for (final entry in groupedOps.entries) {
      final ops = entry.value;
      
      for (final op in ops) {
        await _processOperation(op);
      }
    }
  }

  /// Processa uma operação individual
  Future<void> _processOperation(SyncQueueData operation) async {
    final callback = _callbacks[operation.entityType];
    if (callback == null) {
      await _markOperationFailed(
        operation,
        'Callback não registrado para ${operation.entityType}',
      );
      return;
    }

    // Marca como processando
    await _updateOperationStatus(
      operation.id,
      false,
    );

    try {
      final data = operation.data != null ? jsonDecode(operation.data!) as Map<String, dynamic> : <String, dynamic>{};
      final type = WriteOperationType.values
          .firstWhere((t) => t.name == operation.operation);

      final result = await callback(
        type,
        operation.entityType,
        operation.entityId,
        data,
      );

      if (result.success) {
        await _markOperationCompleted(operation, result);
      } else {
        await _handleOperationFailure(operation, result.error ?? 'Erro desconhecido');
      }

      _resultController.add(result);
    } catch (e) {
      // TODO: Implementar logging framework
      // Logger.error('Erro ao processar operação ${operation.id}: $e');
      
      await _handleOperationFailure(operation, e.toString());
      
      _resultController.add(WriteOperationResult(
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Trata falha na operação
  Future<void> _handleOperationFailure(SyncQueueData operation, String error) async {
    final newRetryCount = operation.retryCount + 1;
    
    if (newRetryCount >= _config.maxRetries) {
      await _markOperationFailed(operation, error);
    } else {
      await _scheduleRetry(operation, newRetryCount, error);
    }
  }

  /// Agenda nova tentativa com backoff exponencial
  Future<void> _scheduleRetry(SyncQueueData operation, int retryCount, String error) async {
    final delay = _calculateRetryDelay(retryCount);
    final nextAttemptAt = DateTime.now().add(delay);

    await (_database.update(_database.syncQueue)
      ..where((tbl) => tbl.id.equals(operation.id)))
        .write(SyncQueueCompanion(
          retryCount: Value(retryCount),
          nextAttemptAt: Value(nextAttemptAt),
        ));
  }

  /// Calcula delay para retry com backoff exponencial
  Duration _calculateRetryDelay(int retryCount) {
    final delayMs = _config.initialRetryDelay.inMilliseconds *
        pow(_config.backoffMultiplier, retryCount - 1);
    
    final cappedDelayMs = min(delayMs.toInt(), _config.maxRetryDelay.inMilliseconds);
    
    return Duration(milliseconds: cappedDelayMs);
  }

  /// Marca operação como concluída
  Future<void> _markOperationCompleted(SyncQueueData operation, WriteOperationResult result) async {
    await (_database.update(_database.syncQueue)
      ..where((tbl) => tbl.id.equals(operation.id)))
        .write(SyncQueueCompanion(
          completed: const Value(true),
        ));
  }

  /// Marca operação como falhada
  Future<void> _markOperationFailed(SyncQueueData operation, String error) async {
    await (_database.update(_database.syncQueue)
      ..where((tbl) => tbl.id.equals(operation.id)))
        .write(SyncQueueCompanion(
          completed: const Value(true),
        ));
  }

  /// Atualiza status da operação
  Future<void> _updateOperationStatus(String operationId, bool completed) async {
    await (_database.update(_database.syncQueue)
      ..where((tbl) => tbl.id.equals(operationId)))
        .write(SyncQueueCompanion(
          completed: Value(completed),
        ));
  }

  /// Gera ID único para operação
  String _generateOperationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'op_${timestamp}_$random';
  }

  /// Limpa operações antigas concluídas
  Future<void> cleanCompletedOperations({Duration? olderThan}) async {
    final cutoff = DateTime.now().subtract(olderThan ?? const Duration(days: 7));
    
    await (_database.delete(_database.syncQueue)
      ..where((tbl) => 
          tbl.completed.equals(true) &
          tbl.createdAt.isSmallerThanValue(cutoff))).go();
  }

  /// Obtém estatísticas da fila
  Future<Map<String, int>> getQueueStats() async {
    final stats = <String, int>{};
    
    // Operações pendentes
    final pendingCount = await (_database.selectOnly(_database.syncQueue)
      ..addColumns([_database.syncQueue.id.count()])
      ..where(_database.syncQueue.completed.equals(false)))
        .getSingle();
    
    // Operações concluídas
    final completedCount = await (_database.selectOnly(_database.syncQueue)
      ..addColumns([_database.syncQueue.id.count()])
      ..where(_database.syncQueue.completed.equals(true)))
        .getSingle();
    
    stats['pending'] = pendingCount.read(_database.syncQueue.id.count()) ?? 0;
    stats['completed'] = completedCount.read(_database.syncQueue.id.count()) ?? 0;
    
    return stats;
  }

  /// Dispose do serviço
  void dispose() {
    stopProcessing();
    _resultController.close();
  }
}