import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/utilisateur_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

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

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState();

  // Vérifier INE
  Future<UtilisateurModel?> verifierINE(String ine) async {
    state = state.copyWith(isLoading: true, erreur: null);
    try {
      final utilisateur =
      await ref.read(authServiceProvider).verifierINE(ine);
      if (utilisateur == null) {
        state = state.copyWith(
          isLoading: false,
          erreur: 'INE non trouvé. Contactez votre École Doctorale.',
        );
        return null;
      }
      state = state.copyWith(
        isLoading: false,
        ineTemp: ine,
        emailTemp: utilisateur.email,
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
  Future<Map<String, dynamic>> connecter(
      String ine, String motDePasse) async {
    state = state.copyWith(isLoading: true, erreur: null);
    try {
      final result = await ref
          .read(authServiceProvider)
          .connecter(ine, motDePasse);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        erreur: 'Erreur de connexion.',
      );
      return {'success': false, 'message': 'Erreur de connexion.'};
    }
  }

  // Créer compte doctorant
  Future<bool> creerCompteDoctorant(
      String ine, String motDePasse) async {
    state = state.copyWith(isLoading: true, erreur: null);
    try {
      await ref
          .read(authServiceProvider)
          .creerCompteDoctorant(ine, motDePasse);
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
    await ref.read(authServiceProvider).deconnecter();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);