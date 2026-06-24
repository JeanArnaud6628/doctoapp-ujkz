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
    final emailAuth =
        '${ine.toLowerCase().replaceAll(' ', '')}@doctoapp.ujkz';
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
  Future<bool> creerCompteDoctorant(
      String ine, String motDePasse) async {
    final emailAuth =
        '${ine.toLowerCase().replaceAll(' ', '')}@doctoapp.ujkz';
    await _supabase.auth.signUp(
      email: emailAuth,
      password: motDePasse,
    );
    return true;
  }

  // Envoyer OTP
  Future<void> envoyerOTP(String email) async {
    await _supabase.auth.signInWithOtp(email: email);
  }

  // Vérifier OTP
  Future<AuthResponse> verifierOTP(
      String email, String token) async {
    return await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
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