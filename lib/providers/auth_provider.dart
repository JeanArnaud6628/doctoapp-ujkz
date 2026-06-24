import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/utilisateur_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// État de l'authentification
class AuthState {
  final UtilisateurModel? utilisateur;
  final bool isLoading;
  final String? erreur;
  final String? ineTemp;
  final String? emailTemp;

  AuthState({
    this.utilisateur,
    this.isLoading = false,
    this.erreur,
    this.ineTemp,
    this.emailTemp,
  });

  AuthState copyWith({
    UtilisateurModel? utilisateur,
    bool? isLoading,
    String? erreur,
    String? ineTemp,
    String? emailTemp,
  }) {
    return AuthState(
      utilisateur: utilisateur ?? this.utilisateur,
      isLoading: isLoading ?? this.isLoading,
      erreur: erreur,
      ineTemp: ineTemp ?? this.ineTemp,
      emailTemp: emailTemp ?? this.emailTemp,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(AuthState());

  // Vérifier INE
  Future<UtilisateurModel?> verifierINE(String ine) async {
    state = state.copyWith(isLoading: true, erreur: null);
    try {
      final data = await _authService.verifierINE(ine);
      if (data == null) {
        state = state.copyWith(
          isLoading: false,
          erreur: 'INE non trouvé. Contactez votre École Doctorale.',
        );
        return null;
      }
      final utilisateur = UtilisateurModel.fromJson(data);
      state = state.copyWith(
        isLoading: false,
        ineTemp: ine,
        emailTemp: data['email'],
      );
      return utilisateur;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        erreur: 'Erreur de connexion. Réessayez.',
      );
      return null;
    }
  }

  // Connexion
  Future<bool> connecter(String ine, String motDePasse) async {
    state = state.copyWith(isLoading: true, erreur: null);
    try {
      await _authService.connecter(ine, motDePasse);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        erreur: 'INE ou mot de passe incorrect.',
      );
      return false;
    }
  }

  // Créer compte
  Future<bool> creerCompte(String ine, String motDePasse) async {
    state = state.copyWith(isLoading: true, erreur: null);
    try {
      await _authService.creerCompte(ine, motDePasse);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        erreur: 'Erreur lors de la création du compte.',
      );
      return false;
    }
  }

  // Déconnexion
  Future<void> deconnecter() async {
    await _authService.deconnecter();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});