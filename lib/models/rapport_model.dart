class RapportModel {
  final String id;
  final String? titre;
  final int annee;
  final String? fichierPdf;
  final String dateDepot;
  final String statut;
  final String doctorantId;

  RapportModel({
    required this.id,
    this.titre,
    required this.annee,
    this.fichierPdf,
    required this.dateDepot,
    this.statut = 'en attente',
    required this.doctorantId,
  });

  factory RapportModel.fromJson(Map<String, dynamic> json) {
    return RapportModel(
      id: json['id'] ?? '',
      titre: json['titre'],
      annee: json['annee'] ?? 0,
      fichierPdf: json['fichier_pdf'],
      dateDepot: json['date_depot'] ?? '',
      statut: json['statut'] ?? 'en attente',
      doctorantId: json['doctorant_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'titre': titre,
    'annee': annee,
    'fichier_pdf': fichierPdf,
    'statut': statut,
    'doctorant_id': doctorantId,
  };

  String get statutLibelle {
    switch (statut) {
      case 'en attente': return 'En attente';
      case 'valide': return 'Validé';
      case 'rejete': return 'Rejeté';
      default: return statut;
    }
  }
}