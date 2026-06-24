class ManuscritModel {
  final String id;
  final String titre;
  final String? fichierPdf;
  final String dateDepot;
  final String statut;
  final String doctorantId;

  ManuscritModel({
    required this.id,
    required this.titre,
    this.fichierPdf,
    required this.dateDepot,
    this.statut = 'en attente',
    required this.doctorantId,
  });

  factory ManuscritModel.fromJson(Map<String, dynamic> json) {
    return ManuscritModel(
      id: json['id'] ?? '',
      titre: json['titre'] ?? '',
      fichierPdf: json['fichier_pdf'],
      dateDepot: json['date_depot'] ?? '',
      statut: json['statut'] ?? 'en attente',
      doctorantId: json['doctorant_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'titre': titre,
    'fichier_pdf': fichierPdf,
    'statut': statut,
    'doctorant_id': doctorantId,
  };
}