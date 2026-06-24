class SoutenanceModel {
  final String id;
  final String theseId;
  final String dateSoutenance;
  final String heure;
  final String lieu;
  final String presidentJury;
  final String createdAt;

  SoutenanceModel({
    required this.id,
    required this.theseId,
    required this.dateSoutenance,
    required this.heure,
    required this.lieu,
    required this.presidentJury,
    required this.createdAt,
  });

  factory SoutenanceModel.fromJson(Map<String, dynamic> json) {
    return SoutenanceModel(
      id: json['id'] ?? '',
      theseId: json['these_id'] ?? '',
      dateSoutenance: json['date_soutenance'] ?? '',
      heure: json['heure'] ?? '',
      lieu: json['lieu'] ?? '',
      presidentJury: json['president_jury'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'these_id': theseId,
    'date_soutenance': dateSoutenance,
    'heure': heure,
    'lieu': lieu,
    'president_jury': presidentJury,
  };
}