class UtilisateurModel {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String? ine;
  final String role;
  final String? telephone;
  final String? photo;
  final bool actif;
  final String? ecoleDoctorale;
  final String createdAt;

  UtilisateurModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.ine,
    required this.role,
    this.telephone,
    this.photo,
    this.actif = true,
    this.ecoleDoctorale,
    this.createdAt = '',
  });

  factory UtilisateurModel.fromJson(Map<String, dynamic> json) {
    return UtilisateurModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      ine: json['ine'],
      role: json['role'] ?? '',
      telephone: json['telephone'],
      photo: json['photo'],
      actif: json['actif'] ?? true,
      ecoleDoctorale: json['ecole_doctorale'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'ine': ine,
    'role': role,
    'telephone': telephone,
    'actif': actif,
    'ecole_doctorale': ecoleDoctorale,
  };

  String get nomComplet => '$prenom $nom';

  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return '$p$n'.toUpperCase();
  }

  String get nomMasque {
    if (prenom.isEmpty || nom.isEmpty) return '***** *****';
    return '${prenom[0]}***** ${nom[0]}*****';
  }

  String get roleLibelle {
    switch (role) {
      case 'doctorant': return 'Doctorant';
      case 'directeur': return 'Directeur de thèse';
      case 'csi': return 'Membre CSI';
      case 'rapporteur': return 'Rapporteur';
      case 'admin': return 'Administrateur';
      default: return role;
    }
  }
}