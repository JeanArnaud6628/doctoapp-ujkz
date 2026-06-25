class HistoriqueModel {
  final String id;
  final String? theseId;
  final String? utilisateurId;
  final String action;
  final String? details;
  final String? typeAction;
  final String? acteurId;
  final String createdAt;

  HistoriqueModel({
    required this.id,
    this.theseId,
    this.utilisateurId,
    required this.action,
    this.details,
    this.typeAction,
    this.acteurId,
    required this.createdAt,
  });

  factory HistoriqueModel.fromJson(Map<String, dynamic> json) {
    return HistoriqueModel(
      id: json['id'] ?? '',
      theseId: json['these_id'],
      utilisateurId: json['utilisateur_id'],
      action: json['action'] ?? '',
      details: json['details'],
      typeAction: json['type_action'],
      acteurId: json['acteur_id'],
      createdAt: json['created_at'] ?? '',
    );
  }
}