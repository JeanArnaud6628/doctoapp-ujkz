class AlerteModel {
  final String id;
  final String? theseId;
  final String? utilisateurId;
  final String typeAlerte;
  final String message;
  final String niveau;
  final bool resolue;
  final String createdAt;

  AlerteModel({
    required this.id,
    this.theseId,
    this.utilisateurId,
    required this.typeAlerte,
    required this.message,
    this.niveau = 'warning',
    this.resolue = false,
    required this.createdAt,
  });

  factory AlerteModel.fromJson(Map<String, dynamic> json) {
    return AlerteModel(
      id: json['id'] ?? '',
      theseId: json['these_id'],
      utilisateurId: json['utilisateur_id'],
      typeAlerte: json['type_alerte'] ?? '',
      message: json['message'] ?? '',
      niveau: json['niveau'] ?? 'warning',
      resolue: json['resolue'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}