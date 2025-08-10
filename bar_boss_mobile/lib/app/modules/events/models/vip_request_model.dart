import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/core/constants/firestore_keys.dart';

/// Status da solicitação VIP
enum VipRequestStatus {
  pending,   // Pendente
  approved,  // Aprovado
  rejected,  // Rejeitado
  cancelled, // Cancelado
}

/// Extensão para converter o enum para string e vice-versa
extension VipRequestStatusExtension on VipRequestStatus {
  String get name {
    switch (this) {
      case VipRequestStatus.pending:
        return 'pending';
      case VipRequestStatus.approved:
        return 'approved';
      case VipRequestStatus.rejected:
        return 'rejected';
      case VipRequestStatus.cancelled:
        return 'cancelled';
    }
  }
  
  static VipRequestStatus fromString(String status) {
    switch (status) {
      case 'pending':
        return VipRequestStatus.pending;
      case 'approved':
        return VipRequestStatus.approved;
      case 'rejected':
        return VipRequestStatus.rejected;
      case 'cancelled':
        return VipRequestStatus.cancelled;
      default:
        return VipRequestStatus.pending;
    }
  }
}

/// Modelo de dados para solicitações VIP
class VipRequestModel {
  final String id;
  final String eventId;
  final String barId;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userPhone;
  final VipRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  VipRequestModel({
    required this.id,
    required this.eventId,
    required this.barId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// Cria uma instância vazia com valores padrão
  factory VipRequestModel.empty() {
    final now = DateTime.now();
    return VipRequestModel(
      id: '',
      eventId: '',
      barId: '',
      userId: '',
      userName: '',
      userEmail: '',
      userPhone: '',
      status: VipRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  /// Cria uma instância a partir de um documento do Firestore
  factory VipRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VipRequestModel(
      id: doc.id,
      eventId: data[FirestoreKeys.eventId] ?? '',
      barId: data[FirestoreKeys.barId] ?? '',
      userId: data[FirestoreKeys.userId] ?? '',
      userName: data[FirestoreKeys.userName] ?? '',
      userEmail: data[FirestoreKeys.userEmail] ?? '',
      userPhone: data[FirestoreKeys.userPhone],
      status: VipRequestStatusExtension.fromString(
        data[FirestoreKeys.vipRequestStatus] ?? 'pending',
      ),
      createdAt: (data[FirestoreKeys.createdAt] as Timestamp).toDate(),
      updatedAt: (data[FirestoreKeys.updatedAt] as Timestamp).toDate(),
    );
  }
  
  /// Converte o modelo para um mapa para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      FirestoreKeys.eventId: eventId,
      FirestoreKeys.barId: barId,
      FirestoreKeys.userId: userId,
      FirestoreKeys.userName: userName,
      FirestoreKeys.userEmail: userEmail,
      if (userPhone != null && userPhone!.isNotEmpty)
        FirestoreKeys.userPhone: userPhone,
      FirestoreKeys.vipRequestStatus: status.name,
      FirestoreKeys.createdAt: Timestamp.fromDate(createdAt),
      FirestoreKeys.updatedAt: Timestamp.fromDate(DateTime.now()),
    };
  }
  
  /// Cria uma cópia do modelo com os campos atualizados
  VipRequestModel copyWith({
    String? id,
    String? eventId,
    String? barId,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    VipRequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VipRequestModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      barId: barId ?? this.barId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}