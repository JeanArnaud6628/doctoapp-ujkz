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
  final String? theseId;

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
    this.theseId,
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
      theseId: json['these_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'titre': titre,
    'annee': annee,
    'fichier_pdf': fichierPdf,
    'statut': statut,
    'doctorant_id': doctorantId,
    'avis_directeur': avisDirecteur,
    'avis_directeur_date': avisDirecteurDate,
    'commentaire_directeur': commentaireDirecteur,
    'avis_csi': avisCsi,
    'avis_csi_date': avisCsiDate,
    'commentaire_csi': commentaireCsi,
    'these_id': theseId,
  };

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

  String get avisDirecteurLibelle {
    switch (avisDirecteur) {
      case 'favorable': return '✅ Favorable';
      case 'defavorable': return '❌ Défavorable';
      default: return '⏳ En attente';
    }
  }

  String get avisCsiLibelle {
    switch (avisCsi) {
      case 'favorable': return '✅ Favorable';
      case 'defavorable': return '❌ Défavorable';
      case 'signalement': return '⚠️ Signalement';
      default: return '⏳ En attente';
    }
  }
}