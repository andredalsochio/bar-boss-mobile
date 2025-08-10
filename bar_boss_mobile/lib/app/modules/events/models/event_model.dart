import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';

/// Modelo de dados para eventos
class EventModel {
  final String id;
  final String barId;
  final DateTime date;
  final List<String> attractions;
  final List<String>? promotionImages;
  final String? promotionDetails;
  final bool allowVipAccess;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  EventModel({
    required this.id,
    required this.barId,
    required this.date,
    required this.attractions,
    this.promotionImages,
    this.promotionDetails,
    this.allowVipAccess = false,
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// Cria uma instância vazia com valores padrão
  factory EventModel.empty() {
    final now = DateTime.now();
    return EventModel(
      id: '',
      barId: '',
      date: now,
      attractions: [],
      promotionImages: [],
      promotionDetails: '',
      allowVipAccess: false,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  /// Cria uma instância a partir de um documento do Firestore
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      barId: data[FirestoreKeys.barId] ?? '',
      date: (data[FirestoreKeys.eventDate] as Timestamp).toDate(),
      attractions: List<String>.from(data[FirestoreKeys.attractions] ?? []),
      promotionImages: data[FirestoreKeys.promotionImages] != null
          ? List<String>.from(data[FirestoreKeys.promotionImages])
          : null,
      promotionDetails: data[FirestoreKeys.promotionDetails],
      allowVipAccess: data[FirestoreKeys.allowVipAccess] ?? false,
      createdAt: (data[FirestoreKeys.createdAt] as Timestamp).toDate(),
      updatedAt: (data[FirestoreKeys.updatedAt] as Timestamp).toDate(),
    );
  }
  
  /// Converte o modelo para um mapa para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      FirestoreKeys.barId: barId,
      FirestoreKeys.eventDate: Timestamp.fromDate(date),
      FirestoreKeys.attractions: attractions,
      if (promotionImages != null && promotionImages!.isNotEmpty)
        FirestoreKeys.promotionImages: promotionImages,
      if (promotionDetails != null && promotionDetails!.isNotEmpty)
        FirestoreKeys.promotionDetails: promotionDetails,
      FirestoreKeys.allowVipAccess: allowVipAccess,
      FirestoreKeys.createdAt: Timestamp.fromDate(createdAt),
      FirestoreKeys.updatedAt: Timestamp.fromDate(DateTime.now()),
    };
  }
  
  /// Cria uma cópia do modelo com os campos atualizados
  EventModel copyWith({
    String? id,
    String? barId,
    DateTime? date,
    List<String>? attractions,
    List<String>? promotionImages,
    String? promotionDetails,
    bool? allowVipAccess,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      barId: barId ?? this.barId,
      date: date ?? this.date,
      attractions: attractions ?? this.attractions,
      promotionImages: promotionImages ?? this.promotionImages,
      promotionDetails: promotionDetails ?? this.promotionDetails,
      allowVipAccess: allowVipAccess ?? this.allowVipAccess,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}