class NotificationModel {
  final String id;
  final String titre;
  final String message;
  final bool lu;
  final String utilisateurId;
  final String createdAt;
  final String? type;
  final String? dateEnvoi;

  NotificationModel({
    required this.id,
    required this.titre,
    required this.message,
    this.lu = false,
    required this.utilisateurId,
    required this.createdAt,
    this.type,
    this.dateEnvoi,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      titre: json['titre'] ?? '',
      message: json['message'] ?? '',
      lu: json['lu'] ?? false,
      utilisateurId: json['utilisateur_id'] ?? '',
      createdAt: json['created_at'] ?? '',
      type: json['type'],
      dateEnvoi: json['date_envoi'],
    );
  }

  Map<String, dynamic> toJson() => {
    'titre': titre,
    'message': message,
    'lu': lu,
    'utilisateur_id': utilisateurId,
    'type': type,
    'date_envoi': dateEnvoi,
  };

  bool get estNonLue => !lu;
}

