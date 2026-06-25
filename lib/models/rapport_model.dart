class RapportModel {
  final String id;
  final String? titre;
  final int annee;
  final String? fichierPdf;
  final String dateDepot;
  final String? dateLimite;
  final String statut;
  final String doctorantId;
  final String avisDirecteur;
  final String? avisDirecteurDate;
  final String? commentaireDirecteur;
  final String avisCsi;
  final String? avisCsiDate;
  final String? commentaireCsi;

  RapportModel({
    required this.id,
    this.titre,
    required this.annee,
    this.fichierPdf,
    required this.dateDepot,
    this.dateLimite,
    this.statut = 'en attente',
    required this.doctorantId,
    this.avisDirecteur = 'en_attente',
    this.avisDirecteurDate,
    this.commentaireDirecteur,
    this.avisCsi = 'en_attente',
    this.avisCsiDate,
    this.commentaireCsi,
  });

  factory RapportModel.fromJson(Map<String, dynamic> json) {
    return RapportModel(
      id: json['id'] ?? '',
      titre: json['titre'],
      annee: json['annee'] ?? 0,
      fichierPdf: json['fichier_pdf'],
      dateDepot: json['date_depot'] ?? '',
      dateLimite: json['date_limite'],
      statut: json['statut'] ?? 'en attente',
      doctorantId: json['doctorant_id'] ?? '',
      avisDirecteur: json['avis_directeur'] ?? 'en_attente',
      avisDirecteurDate: json['avis_directeur_date'],
      commentaireDirecteur: json['commentaire_directeur'],
      avisCsi: json['avis_csi'] ?? 'en_attente',
      avisCsiDate: json['avis_csi_date'],
      commentaireCsi: json['commentaire_csi'],
    );
  }

  bool get enRetard {
    if (dateLimite == null) return false;
    return DateTime.tryParse(dateLimite!)?.isBefore(DateTime.now()) ?? false;
  }

  String get statutLibelle {
    switch (statut) {
      case 'en attente': return 'En attente';
      case 'valide': return 'Validé';
      case 'rejete': return 'Rejeté';
      default: return statut;
    }
  }
}