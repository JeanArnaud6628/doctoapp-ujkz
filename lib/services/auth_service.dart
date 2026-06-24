import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Vérifier si l'INE existe dans la base
  Future<Map<String, dynamic>?> verifierINE(String ine) async {
    try {
      final response = await _supabase
          .from('utilisateurs')
          .select('id, nom, prenom, email, role, actif')
          .eq('ine', ine)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  // Connexion avec INE + mot de passe
  Future<AuthResponse> connecter(String ine, String motDePasse) async {

    // Recherche l'utilisateur grâce à son INE
    final data = await _supabase
        .from('utilisateurs')
        .select('email')
        .eq('ine', ine)
        .single();

    final email = data['email'];

    // Connexion avec l'email récupéré
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: motDePasse,
    );
  }

  // Créer un compte
  Future<AuthResponse> creerCompte(String ine, String motDePasse) async {
    final email = '${ine.toLowerCase()}@doctoapp.ujkz';
    return await _supabase.auth.signUp(
      email: email,
      password: motDePasse,
    );
  }


  // Envoyer OTP par email
  Future<void> envoyerOTP(String email) async {
    await _supabase.auth.signInWithOtp(email: email);
  }

  // Vérifier OTP
  Future<AuthResponse> verifierOTP(String email, String token) async {
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

  // Utilisateur connecté
  User? get utilisateurActuel => _supabase.auth.currentUser;

  // Session active
  Session? get sessionActuelle => _supabase.auth.currentSession;
}