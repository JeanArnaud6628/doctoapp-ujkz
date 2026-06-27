import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/utilisateur_model.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Vérifier INE dans la base
  Future<UtilisateurModel?> verifierINE(String ine) async {
    try {
      final response = await _supabase
          .from('utilisateurs')
          .select()
          .eq('ine', ine)
          .maybeSingle();
      if (response == null) return null;
      return UtilisateurModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Connexion — vérifie aussi si compte actif
  Future<Map<String, dynamic>> connecter(
      String ine, String motDePasse) async {
    // 1. Vérifier dans la table utilisateurs
    final utilisateur = await _supabase
        .from('utilisateurs')
        .select()
        .eq('ine', ine)
        .maybeSingle();

    if (utilisateur == null) {
      return {'success': false, 'message': 'INE non trouvé.'};
    }

    if (utilisateur['actif'] == false) {
      return {
        'success': false,
        'message': 'Compte désactivé. Contactez votre École Doctorale.'
      };
    }

    // 2. Connexion Supabase Auth
    final emailAuth = utilisateur['email'] as String; // ← admin@gmail.com

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: emailAuth,
        password: motDePasse,
      );
      return {
        'success': true,
        'role': utilisateur['role'],
        'user': UtilisateurModel.fromJson(utilisateur),
      };
    } catch (e) {
      return {'success': false, 'message': 'Mot de passe incorrect.'};
    }
  }

  // Créer compte doctorant (self-service)
  // ── CRÉER COMPTE DOCTORANT (self-service) ──
  // MODIFIÉ : Gère le statut "en_attente_activation"
  Future<bool> creerCompteDoctorant(String ine, String motDePasse) async {
    final emailAuth = '${ine.toLowerCase().replaceAll(' ', '')}@doctoapp.ujkz';

    // 1. Vérifier que le doctorant existe et est en attente
    final doctorant = await _supabase
        .from('utilisateurs')
        .select()
        .eq('ine', ine)
        .maybeSingle();

    if (doctorant == null) {
      throw Exception('INE non trouvé. Contactez l\'administration.');
    }

    if (doctorant['statut_compte'] != 'en_attente_activation') {
      throw Exception('Ce compte n\'est pas en attente d\'activation.');
    }

    // 2. Créer le compte dans Supabase Auth
    await _supabase.auth.signUp(
      email: emailAuth,
      password: motDePasse,
    );

    // 3. Mettre à jour le statut du doctorant
    await _supabase
        .from('utilisateurs')
        .update({
      'actif': true,
      'statut_compte': 'actif',
      'date_activation': DateTime.now().toIso8601String(),
    })
        .eq('ine', ine);

    return true;
  }

  // ── ENVOYER OTP (code numérique) ──
  Future<void> envoyerOTP(String email) async {
    // Utiliser 'email' comme type pour le Magic Link
    await _supabase.auth.signInWithOtp(
      email: email,
    );
  }

// ── VÉRIFIER OTP (avec le token du lien) ──
  Future<AuthResponse> verifierOTP(String email, String token) async {
    // Le 'token' est le code à 6 chiffres que l'utilisateur a reçu
    // Si l'utilisateur a cliqué sur le lien, il faut utiliser le token du lien
    return await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email, // ← Utiliser 'email' pour le Magic Link
    );
  }

  // Déconnexion
  Future<void> deconnecter() async {
    await _supabase.auth.signOut();
  }

  // Récupérer rôle utilisateur connecté
  Future<String?> getRoleUtilisateurConnecte() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      final response = await _supabase
          .from('utilisateurs')
          .select('role, actif')
          .eq('email', user.email ?? '')
          .maybeSingle();
      if (response == null) return null;
      if (response['actif'] == false) return 'inactif';
      return response['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  User? get utilisateurActuel => _supabase.auth.currentUser;
  Session? get sessionActuelle => _supabase.auth.currentSession;
}