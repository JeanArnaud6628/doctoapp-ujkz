class UtilisateurModel {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String? ine;
  final String role;
  final String? photo;
  final String? telephone;
  final bool actif;

  UtilisateurModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.ine,
    required this.role,
    this.photo,
    this.telephone,
    this.actif = true,
  });

  factory UtilisateurModel.fromJson(Map<String, dynamic> json) {
    return UtilisateurModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      ine: json['ine'],
      role: json['role'] ?? '',
      photo: json['photo'],
      telephone: json['telephone'],
      actif: json['actif'] ?? true,
    );
  }

  String get nomComplet => '$prenom $nom';

  String get nomMasque {
    if (prenom.isEmpty || nom.isEmpty) return '***** *****';
    return '${prenom[0]}***** ${nom[0]}*****';
  }

  String get initiales {
    if (prenom.isEmpty || nom.isEmpty) return 'XX';
    return '${prenom[0]}${nom[0]}'.toUpperCase();
  }
}