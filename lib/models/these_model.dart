class TheseModel {
  final String id;
  final String titre;
  final String? specialite;
  final String? resume;
  final String? dateInscription;
  final String? dateDebut;
  final String? dateFinPrevue;
  final String etat;
  final String etapeActuelle;
  final int anneeEnCours;
  final String doctorantId;
  final String? directeurId;
  final String? motsCles;
  final String? protocoleUrl;
  final bool quitusDirecteur;
  final String? quitusDirecteurDate;
  final bool quitusCsi;
  final String? quitusCsiDate;
  final bool validationAdmin;

  TheseModel({
    required this.id,
    required this.titre,
    this.specialite,
    this.resume,
    this.dateInscription,
    this.dateDebut,
    this.dateFinPrevue,
    this.etat = 'en cours',
    this.etapeActuelle = 'enregistree',
    this.anneeEnCours = 1,
    required this.doctorantId,
    this.directeurId,
    this.motsCles,
    this.protocoleUrl,
    this.quitusDirecteur = false,
    this.quitusDirecteurDate,
    this.quitusCsi = false,
    this.quitusCsiDate,
    this.validationAdmin = false,
  });

  factory TheseModel.fromJson(Map<String, dynamic> json) {
    return TheseModel(
      id: json['id'] ?? '',
      titre: json['titre'] ?? '',
      specialite: json['specialite'],
      resume: json['resume'],
      dateInscription: json['date_inscription'],
      dateDebut: json['date_debut'],
      dateFinPrevue: json['date_fin_prevue'],
      etat: json['etat'] ?? 'en cours',
      etapeActuelle: json['etape_actuelle'] ?? 'enregistree',
      anneeEnCours: json['annee_en_cours'] ?? 1,
      doctorantId: json['doctorant_id'] ?? '',
      directeurId: json['directeur_id'],
      motsCles: json['mots_cles'],
      protocoleUrl: json['protocole_url'],
      quitusDirecteur: json['quitus_directeur'] ?? false,
      quitusDirecteurDate: json['quitus_directeur_date'],
      quitusCsi: json['quitus_csi'] ?? false,
      quitusCsiDate: json['quitus_csi_date'],
      validationAdmin: json['validation_admin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'titre': titre,
    'specialite': specialite,
    'resume': resume,
    'etat': etat,
    'etape_actuelle': etapeActuelle,
    'annee_en_cours': anneeEnCours,
    'doctorant_id': doctorantId,
    'directeur_id': directeurId,
    'mots_cles': motsCles,
  };

  int get progression {
    const etapes = {
      'enregistree': 5,
      'directeur_choisi': 15,
      'directeur_valide': 20,
      'csi_affecte': 25,
      'rapport_annuel_1': 35,
      'rapport_annuel_2': 50,
      'rapport_annuel_3': 65,
      'manuscrit_depose': 70,
      'quitus_directeur': 75,
      'quitus_csi': 80,
      'rapporteurs_affectes': 85,
      'evaluation_rapporteurs': 90,
      'soutenance_programmee': 95,
      'soutenance_realisee': 100,
    };
    return etapes[etapeActuelle] ?? 0;
  }

  String get etapeLibelle {
    const libelles = {
      'enregistree': 'Sujet enregistré',
      'directeur_choisi': 'Directeur choisi',
      'directeur_valide': 'Directeur validé',
      'csi_affecte': 'CSI affecté',
      'rapport_annuel_1': 'Rapport Annuel 1',
      'rapport_annuel_2': 'Rapport Annuel 2',
      'rapport_annuel_3': 'Rapport Annuel 3',
      'manuscrit_depose': 'Manuscrit déposé',
      'quitus_directeur': 'Quitus Directeur',
      'quitus_csi': 'Quitus CSI',
      'rapporteurs_affectes': 'Rapporteurs affectés',
      'evaluation_rapporteurs': 'Évaluation rapporteurs',
      'soutenance_programmee': 'Soutenance programmée',
      'soutenance_realisee': 'Soutenance réalisée',
    };
    return libelles[etapeActuelle] ?? etapeActuelle;
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

  List<String> get motsClesList {
    if (motsCles == null || motsCles!.isEmpty) return [];
    return motsCles!.split(',').map((e) => e.trim()).toList();
  }
}