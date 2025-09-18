import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bar_boss_mobile/app/core/schema/firestore_keys.dart';

/// Enum para os tipos de papel/função de um membro no bar
enum MemberRole {
  owner,
  admin,
  editor;

  /// Converte o enum para string para salvar no Firestore
  String get value {
    switch (this) {
      case MemberRole.owner:
        return FirestoreKeys.roleOwner;
      case MemberRole.admin:
        return FirestoreKeys.roleAdmin;
      case MemberRole.editor:
        return FirestoreKeys.roleEditor;
    }
  }

  /// Cria o enum a partir de uma string do Firestore
  static MemberRole fromString(String value) {
    switch (value) {
      case FirestoreKeys.roleOwner:
        return MemberRole.owner;
      case FirestoreKeys.roleAdmin:
        return MemberRole.admin;
      case FirestoreKeys.roleEditor:
        return MemberRole.editor;
      default:
        return MemberRole.editor; // Padrão
    }
  }

  /// Retorna o nome amigável do papel
  String get displayName {
    switch (this) {
      case MemberRole.owner:
        return 'Proprietário';
      case MemberRole.admin:
        return 'Administrador';
      case MemberRole.editor:
        return 'Editor';
    }
  }
}

/// Modelo de dados para membros de um bar (/bars/{barId}/members/{uid})
class MemberModel {
  final String uid;
  final MemberRole role;
  final String? invitedByUid;
  final DateTime createdAt;
  final String? barId;  // ID do bar para referência
  final String? barName;  // Nome do bar para exibição

  MemberModel({
    required this.uid,
    required this.role,
    this.invitedByUid,
    required this.createdAt,
    this.barId,
    this.barName,
  });

  /// Cria uma instância vazia com valores padrão
  factory MemberModel.empty() {
    return MemberModel(
      uid: '',
      role: MemberRole.editor,
      invitedByUid: null,
      createdAt: DateTime.now(),
      barId: null,
      barName: null,
    );
  }

  /// Cria uma instância a partir de um documento do Firestore
  factory MemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberModel(
      uid: data[FirestoreKeys.memberUid] ?? doc.id,
      role: MemberRole.fromString(data[FirestoreKeys.memberRole] ?? FirestoreKeys.roleEditor),
      invitedByUid: data[FirestoreKeys.memberInvitedByUid],
      createdAt: (data[FirestoreKeys.memberCreatedAt] as Timestamp).toDate(),
      barId: data['barId'],  // Campo para referência do bar
      barName: data['barName'],  // Nome do bar para exibição
    );
  }

  /// Converte o modelo para um mapa para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      FirestoreKeys.memberUid: uid,
      FirestoreKeys.memberRole: role.value,
      if (invitedByUid != null) FirestoreKeys.memberInvitedByUid: invitedByUid,
      FirestoreKeys.memberCreatedAt: Timestamp.fromDate(createdAt),
      if (barId != null) 'barId': barId,  // ID do bar para referência
      if (barName != null) 'barName': barName,  // Nome do bar para exibição
    };
  }

  /// Cria uma cópia do modelo com campos atualizados
  MemberModel copyWith({
    String? uid,
    MemberRole? role,
    String? invitedByUid,
    DateTime? createdAt,
    String? barId,
    String? barName,
  }) {
    return MemberModel(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      invitedByUid: invitedByUid ?? this.invitedByUid,
      createdAt: createdAt ?? this.createdAt,
      barId: barId ?? this.barId,
      barName: barName ?? this.barName,
    );
  }

  /// Verifica se o membro tem permissão de proprietário
  bool get isOwner => role == MemberRole.owner;

  /// Verifica se o membro tem permissão de administrador ou superior
  bool get isAdminOrAbove => role == MemberRole.owner || role == MemberRole.admin;

  /// Verifica se o membro pode editar conteúdo
  bool get canEdit => true; // Todos os membros podem editar

  /// Verifica se o membro pode gerenciar outros membros
  bool get canManageMembers => isAdminOrAbove;

  /// Verifica se o membro pode gerenciar configurações do bar
  bool get canManageBarSettings => isOwner;

  @override
  String toString() {
    return 'MemberModel(uid: $uid, role: ${role.displayName}, invitedByUid: $invitedByUid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemberModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}