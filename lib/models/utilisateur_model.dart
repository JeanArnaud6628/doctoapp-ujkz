import 'package:flutter/material.dart';

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

  // ─── NOUVEAUX CHAMPS POUR LA GESTION DES COMPTES ───
  final String? statutCompte; // 'en_attente_activation' | 'actif' | 'inactif' | 'supprime'
  final String? dateActivation;
  final String? motifDesactivation;
  final String? dateDesactivation;
  final String? dateReactivation;
  final String? dateSuppression;

  // ─── NOUVEAUX CHAMPS POUR LE DOSSIER DOCTORANT ───
  final String? sexe;
  final String? dateNaissance;
  final String? formationDoctorale;
  final String? departement;
  final String? laboratoire;
  final String? promotion;
  final int? anneeInscription;
  final String? sujetProvisoire;

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
    // Nouveaux champs
    this.statutCompte,
    this.dateActivation,
    this.motifDesactivation,
    this.dateDesactivation,
    this.dateReactivation,
    this.dateSuppression,
    this.sexe,
    this.dateNaissance,
    this.formationDoctorale,
    this.departement,
    this.laboratoire,
    this.promotion,
    this.anneeInscription,
    this.sujetProvisoire,
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
      // Nouveaux champs
      statutCompte: json['statut_compte'] ?? 'actif',
      dateActivation: json['date_activation'],
      motifDesactivation: json['motif_desactivation'],
      dateDesactivation: json['date_desactivation'],
      dateReactivation: json['date_reactivation'],
      dateSuppression: json['date_suppression'],
      sexe: json['sexe'],
      dateNaissance: json['date_naissance'],
      formationDoctorale: json['formation_doctorale'],
      departement: json['departement'],
      laboratoire: json['laboratoire'],
      promotion: json['promotion'],
      anneeInscription: json['annee_inscription'],
      sujetProvisoire: json['sujet_provisoire'],
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
    // Nouveaux champs
    'statut_compte': statutCompte,
    'date_activation': dateActivation,
    'motif_desactivation': motifDesactivation,
    'date_desactivation': dateDesactivation,
    'date_reactivation': dateReactivation,
    'date_suppression': dateSuppression,
    'sexe': sexe,
    'date_naissance': dateNaissance,
    'formation_doctorale': formationDoctorale,
    'departement': departement,
    'laboratoire': laboratoire,
    'promotion': promotion,
    'annee_inscription': anneeInscription,
    'sujet_provisoire': sujetProvisoire,
  };

  // ─── GETTERS UTILES ───

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

  // ─── GETTERS POUR LE STATUT ───

  String get statutLibelle {
    switch (statutCompte) {
      case 'en_attente_activation': return 'En attente d\'activation';
      case 'actif': return 'Actif';
      case 'inactif': return 'Inactif';
      case 'supprime': return 'Supprimé';
      default: return 'Inconnu';
    }
  }

  // ✅ CORRIGÉ : couleurs valides avec le bon format
  Color get statutCouleur {
    switch (statutCompte) {
      case 'en_attente_activation': return const Color(0xFFFF9800); // Orange
      case 'actif': return const Color(0xFF4CAF50); // Vert
      case 'inactif': return const Color(0xFFF44336); // Rouge
      case 'supprime': return const Color(0xFF9E9E9E); // Gris
      default: return const Color(0xFF9E9E9E); // Gris
    }
  }

  bool get estEnAttente => statutCompte == 'en_attente_activation';
  bool get estActif => statutCompte == 'actif' && actif == true;
  bool get estInactif => statutCompte == 'inactif' || actif == false;
}