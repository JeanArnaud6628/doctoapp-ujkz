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
  final String? protocoleUrl;

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
    this.protocoleUrl,
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
      protocoleUrl: json['protocole_url'],
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
    'protocole_url': protocoleUrl,
  };

  int get progression {
    switch (etat) {
      case 'enregistree': return 10;
      case 'en cours': return 40;
      case 'en instruction': return 70;
      case 'soutenue': return 100;
      default: return 0;
    }
  }

  String get etatLibelle {
    switch (etat) {
      case 'enregistree': return 'Enregistrée';
      case 'en cours': return 'Suivi annuel';
      case 'en instruction': return 'En instruction';
      case 'soutenue': return 'Soutenue';
      default: return etat;
    }
  }
}