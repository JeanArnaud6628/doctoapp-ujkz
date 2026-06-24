import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/utilisateur_model.dart';
import '../models/these_model.dart';
import '../models/soutenance_model.dart';
import '../models/notification_model.dart';

class AdminService {
  final _supabase = Supabase.instance.client;

  // ── STATISTIQUES DASHBOARD ───────────────────────────────────────────────
  Future<Map<String, int>> getStatistiques() async {
    try {
      final doctorants = await _supabase
          .from('utilisateurs')
          .select('id')
          .eq('role', 'doctorant');
      final directeurs = await _supabase
          .from('utilisateurs')
          .select('id')
          .eq('role', 'directeur');
      final rapporteurs = await _supabase
          .from('utilisateurs')
          .select('id')
          .eq('role', 'rapporteur');
      final csi = await _supabase
          .from('utilisateurs')
          .select('id')
          .eq('role', 'csi');
      final theses = await _supabase
          .from('theses')
          .select('id');
      final soutenances = await _supabase
          .from('soutenances')
          .select('id');
      final manuscrits = await _supabase
          .from('manuscrits')
          .select('id');

      return {
        'doctorants': (doctorants as List).length,
        'directeurs': (directeurs as List).length,
        'rapporteurs': (rapporteurs as List).length,
        'csi': (csi as List).length,
        'theses': (theses as List).length,
        'soutenances': (soutenances as List).length,
        'manuscrits': (manuscrits as List).length,
      };
    } catch (e) {
      return {
        'doctorants': 0,
        'directeurs': 0,
        'rapporteurs': 0,
        'csi': 0,
        'theses': 0,
        'soutenances': 0,
        'manuscrits': 0,
      };
    }
  }

  // ── UTILISATEURS ─────────────────────────────────────────────────────────
  Future<List<UtilisateurModel>> getUtilisateursByRole(String role) async {
    final response = await _supabase
        .from('utilisateurs')
        .select()
        .eq('role', role)
        .order('nom');
    return (response as List)
        .map((e) => UtilisateurModel.fromJson(e))
        .toList();
  }

  Future<UtilisateurModel?> getUtilisateurById(String id) async {
    try {
      final response = await _supabase
          .from('utilisateurs')
          .select()
          .eq('id', id)
          .single();
      return UtilisateurModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<UtilisateurModel> creerUtilisateur({
    required String nom,
    required String prenom,
    required String email,
    required String role,
    String? telephone,
    String? ine,
  }) async {
    // Créer compte Supabase Auth
    final authEmail = role == 'doctorant'
        ? '${(ine ?? email).toLowerCase().replaceAll(' ', '')}@doctoapp.ujkz'
        : email;

    await _supabase.auth.admin.createUser(
      AdminUserAttributes(
        email: authEmail,
        password: 'DoctoApp2026!',
        emailConfirm: true,
      ),
    );

    // Insérer dans la table utilisateurs
    final response = await _supabase.from('utilisateurs').insert({
      'nom': nom,
      'prenom': prenom,
      'email': authEmail,
      'role': role,
      'telephone': telephone,
      'ine': ine,
      'actif': true,
    }).select().single();

    return UtilisateurModel.fromJson(response);
  }

  Future<void> modifierUtilisateur(
      String id, Map<String, dynamic> data) async {
    await _supabase.from('utilisateurs').update(data).eq('id', id);
  }

  Future<void> supprimerUtilisateur(String id) async {
    await _supabase.from('utilisateurs').update({'actif': false}).eq('id', id);
  }

  Future<List<UtilisateurModel>> rechercherUtilisateurs(
      String query, String role) async {
    final response = await _supabase
        .from('utilisateurs')
        .select()
        .eq('role', role)
        .or('nom.ilike.%$query%,prenom.ilike.%$query%,email.ilike.%$query%')
        .order('nom');
    return (response as List)
        .map((e) => UtilisateurModel.fromJson(e))
        .toList();
  }

  // ── THÈSES ───────────────────────────────────────────────────────────────
  Future<List<TheseModel>> getTheses() async {
    final response = await _supabase
        .from('theses')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((e) => TheseModel.fromJson(e)).toList();
  }

  Future<void> updateEtatThese(String theseId, String etat) async {
    await _supabase
        .from('theses')
        .update({'etat': etat}).eq('id', theseId);
  }

  // ── SOUTENANCES ──────────────────────────────────────────────────────────
  Future<List<SoutenanceModel>> getSoutenances() async {
    final response = await _supabase
        .from('soutenances')
        .select()
        .order('date_soutenance');
    return (response as List)
        .map((e) => SoutenanceModel.fromJson(e))
        .toList();
  }

  Future<SoutenanceModel> programmerSoutenance({
    required String theseId,
    required String date,
    required String heure,
    required String lieu,
    required String presidentJury,
  }) async {
    final response = await _supabase.from('soutenances').insert({
      'these_id': theseId,
      'date_soutenance': date,
      'heure': heure,
      'lieu': lieu,
      'president_jury': presidentJury,
    }).select().single();
    return SoutenanceModel.fromJson(response);
  }

  Future<void> modifierSoutenance(
      String id, Map<String, dynamic> data) async {
    await _supabase.from('soutenances').update(data).eq('id', id);
  }

  // ── NOTIFICATIONS ────────────────────────────────────────────────────────
  Future<void> envoyerNotification({
    required String utilisateurId,
    required String titre,
    required String message,
  }) async {
    await _supabase.from('notifications').insert({
      'utilisateur_id': utilisateurId,
      'titre': titre,
      'message': message,
      'lu': false,
    });
  }

  Future<List<NotificationModel>> getNotificationsRecentes() async {
    final response = await _supabase
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(10);
    return (response as List)
        .map((e) => NotificationModel.fromJson(e))
        .toList();
  }

  // ── MANUSCRITS ───────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getManuscritsEnAttente() async {
    final response = await _supabase
        .from('manuscrits')
        .select()
        .eq('statut', 'en attente')
        .order('created_at', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<void> validerManuscrit(String manuscritId) async {
    await _supabase
        .from('manuscrits')
        .update({'statut': 'valide'}).eq('id', manuscritId);
  }

  Future<void> rejeterManuscrit(String manuscritId) async {
    await _supabase
        .from('manuscrits')
        .update({'statut': 'rejete'}).eq('id', manuscritId);
  }
}