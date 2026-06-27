class ManuscritModel {
  final String id;
  final String titre;
  final String? fichierPdf;
  final String dateDepot;
  final String statut;
  final String doctorantId;
  final String? theseId;

  ManuscritModel({
    required this.id,
    required this.titre,
    this.fichierPdf,
    required this.dateDepot,
    this.statut = 'en attente',
    required this.doctorantId,
    this.theseId,
  });

  factory ManuscritModel.fromJson(Map<String, dynamic> json) {
    return ManuscritModel(
      id: json['id'] ?? '',
      titre: json['titre'] ?? '',
      fichierPdf: json['fichier_pdf'],
      dateDepot: json['date_depot'] ?? '',
      statut: json['statut'] ?? 'en attente',
      doctorantId: json['doctorant_id'] ?? '',
      theseId: json['these_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'titre': titre,
    'fichier_pdf': fichierPdf,
    'statut': statut,
    'doctorant_id': doctorantId,
    'these_id': theseId,
  };

  bool get estValide => statut == 'valide';
  bool get estEnAttente => statut == 'en attente';
  bool get estRejete => statut == 'rejete';
}