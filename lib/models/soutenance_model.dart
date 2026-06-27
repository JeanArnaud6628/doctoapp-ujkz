class SoutenanceModel {
  final String id;
  final String theseId;
  final String dateSoutenance;
  final String heure;
  final String lieu;
  final String presidentJury;
  final String createdAt;
  final String? statut;
  final String? resultat;
  final String? mention;

  SoutenanceModel({
    required this.id,
    required this.theseId,
    required this.dateSoutenance,
    required this.heure,
    required this.lieu,
    required this.presidentJury,
    required this.createdAt,
    this.statut,
    this.resultat,
    this.mention,
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
      statut: json['statut'] ?? 'programmee',
      resultat: json['resultat'],
      mention: json['mention'],
    );
  }

  Map<String, dynamic> toJson() => {
    'these_id': theseId,
    'date_soutenance': dateSoutenance,
    'heure': heure,
    'lieu': lieu,
    'president_jury': presidentJury,
    'statut': statut,
    'resultat': resultat,
    'mention': mention,
  };

  String get statutLibelle {
    switch (statut) {
      case 'programmee': return 'Programmée';
      case 'realisee': return 'Réalisée';
      case 'annulee': return 'Annulée';
      default: return 'Inconnu';
    }
  }

  String get resultatLibelle {
    switch (resultat) {
      case 'admis': return 'Admis ✅';
      case 'ajourne': return 'Ajourné ❌';
      default: return 'En attente';
    }
  }
}