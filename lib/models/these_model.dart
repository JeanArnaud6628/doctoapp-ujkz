class TheseModel {
  final String id;
  final String titre;
  final String? specialite;
  final String? resume;
  final String? dateInscription;
  final String etat;
  final String doctorantId;
  final String? directeurId;
  final String? motsCles;

  // Champs du cycle doctoral
  final String? etapeActuelle;
  final int? anneeEnCours;
  final bool? quitusDirecteur;
  final bool? quitusCsi;
  final bool? validationAdmin;
  final String? dateValidationAdmin;

  TheseModel({
    required this.id,
    required this.titre,
    this.specialite,
    this.resume,
    this.dateInscription,
    this.etat = 'en cours',
    required this.doctorantId,
    this.directeurId,
    this.motsCles,
    this.etapeActuelle,
    this.anneeEnCours,
    this.quitusDirecteur,
    this.quitusCsi,
    this.validationAdmin,
    this.dateValidationAdmin,
  });

  factory TheseModel.fromJson(Map<String, dynamic> json) {
    return TheseModel(
      id: json['id'] ?? '',
      titre: json['titre'] ?? '',
      specialite: json['specialite'],
      resume: json['resume'],
      dateInscription: json['date_inscription'],
      etat: json['etat'] ?? 'en cours',
      doctorantId: json['doctorant_id'] ?? '',
      directeurId: json['directeur_id'],
      motsCles: json['mots_cles'],
      etapeActuelle: json['etape_actuelle'] ?? 'enregistree',
      anneeEnCours: json['annee_en_cours'] ?? 1,
      quitusDirecteur: json['quitus_directeur'] ?? false,
      quitusCsi: json['quitus_csi'] ?? false,
      validationAdmin: json['validation_admin'] ?? false,
      dateValidationAdmin: json['date_validation_admin'],
    );
  }

  Map<String, dynamic> toJson() => {
    'titre': titre,
    'specialite': specialite,
    'resume': resume,
    'etat': etat,
    'doctorant_id': doctorantId,
    'directeur_id': directeurId,
    'mots_cles': motsCles,
    'etape_actuelle': etapeActuelle,
    'annee_en_cours': anneeEnCours,
    'quitus_directeur': quitusDirecteur,
    'quitus_csi': quitusCsi,
    'validation_admin': validationAdmin,
    'date_validation_admin': dateValidationAdmin,
  };

  int get progression {
    switch (etapeActuelle) {
      case 'enregistree': return 5;
      case 'directeur_choisi': return 10;
      case 'directeur_valide': return 15;
      case 'csi_affecte': return 20;
      case 'rapport_annuel_1': return 30;
      case 'rapport_annuel_1_valide': return 35;
      case 'rapport_annuel_2': return 45;
      case 'rapport_annuel_2_valide': return 50;
      case 'rapport_annuel_3': return 60;
      case 'rapport_annuel_3_valide': return 65;
      case 'manuscrit_depose': return 70;
      case 'quitus_directeur': return 75;
      case 'quitus_csi': return 80;
      case 'validation_admin': return 85;
      case 'rapporteurs_affectes': return 90;
      case 'evaluation_rapporteurs': return 92;
      case 'soutenance_programmee': return 95;
      case 'soutenance_realisee': return 100;
      default: return 5;
    }
  }

  String get etatLibelle {
    switch (etat) {
      case 'enregistree': return 'Enregistrée';
      case 'en cours': return 'En cours';
      case 'en instruction': return 'En instruction';
      case 'soutenue': return 'Soutenue';
      case 'abandonnee': return 'Abandonnée';
      default: return etat;
    }
  }

  String get etapeLibelle {
    switch (etapeActuelle) {
      case 'enregistree': return 'Sujet enregistré';
      case 'directeur_choisi': return 'Directeur choisi';
      case 'directeur_valide': return 'Directeur validé';
      case 'csi_affecte': return 'CSI affecté';
      case 'rapport_annuel_1': return 'Rapport annuel 1 en cours';
      case 'rapport_annuel_1_valide': return 'Rapport annuel 1 validé';
      case 'rapport_annuel_2': return 'Rapport annuel 2 en cours';
      case 'rapport_annuel_2_valide': return 'Rapport annuel 2 validé';
      case 'rapport_annuel_3': return 'Rapport annuel 3 en cours';
      case 'rapport_annuel_3_valide': return 'Rapport annuel 3 validé';
      case 'manuscrit_depose': return 'Manuscrit déposé';
      case 'quitus_directeur': return 'En attente quitus directeur';
      case 'quitus_csi': return 'En attente quitus CSI';
      case 'validation_admin': return 'En attente validation admin';
      case 'rapporteurs_affectes': return 'Rapporteurs affectés';
      case 'evaluation_rapporteurs': return 'Évaluation en cours';
      case 'soutenance_programmee': return 'Soutenance programmée';
      case 'soutenance_realisee': return 'Soutenance réalisée';
      default: return 'Sujet enregistré';
    }
  }
}