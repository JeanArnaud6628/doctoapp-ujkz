import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/utilisateur_model.dart';
import '../models/these_model.dart';
import '../models/soutenance_model.dart';
import '../models/notification_model.dart';

class AdminService {
  final _supabase = Supabase.instance.client;

  // ── STATISTIQUES ─────────────────────────────────────────────────────────
  Future<Map<String, int>> getStatistiques() async {
    try {
      final futures = await Future.wait([
        _supabase.from('utilisateurs').select('id').eq('role', 'doctorant'),
        _supabase.from('utilisateurs').select('id').eq('role', 'directeur'),
        _supabase.from('utilisateurs').select('id').eq('role', 'rapporteur'),
        _supabase.from('utilisateurs').select('id').eq('role', 'csi'),
        _supabase.from('theses').select('id'),
        _supabase.from('soutenances').select('id'),
        _supabase.from('manuscrits').select('id'),
      ]);
      return {
        'doctorants': (futures[0] as List).length,
        'directeurs': (futures[1] as List).length,
        'rapporteurs': (futures[2] as List).length,
        'csi': (futures[3] as List).length,
        'theses': (futures[4] as List).length,
        'soutenances': (futures[5] as List).length,
        'manuscrits': (futures[6] as List).length,
      };
    } catch (e) {
      return {'doctorants': 0, 'directeurs': 0, 'rapporteurs': 0,
        'csi': 0, 'theses': 0, 'soutenances': 0, 'manuscrits': 0};
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

  // Créer utilisateur (admin crée directeur/CSI/rapporteur)
  // L'INE est utilisé comme identifiant — mot de passe par défaut envoyé
  Future<UtilisateurModel> creerUtilisateur({
    required String nom,
    required String prenom,
    required String email,
    required String role,
    String? ine,
    String? telephone,
    String? ecoleDoctorale,
    String? grade,
    String? specialite,
  }) async {
    // Créer dans Supabase Auth avec mot de passe temporaire
    final emailAuth =
        '${ine!.toLowerCase().replaceAll(' ', '')}@doctoapp.ujkz';
    const mdpTemp = 'DoctoApp2026!';

    try {
      await _supabase.auth.signUp(
        email: emailAuth,
        password: mdpTemp,
      );
    } catch (_) {}

    // Insérer dans la table utilisateurs
    final response = await _supabase.from('utilisateurs').insert({
      'nom': nom,
      'prenom': prenom,
      'email': emailAuth,
      'ine': ine,
      'role': role,
      'telephone': telephone,
      'actif': true,
      'ecole_doctorale': ecoleDoctorale,
    }).select().single();

    return UtilisateurModel.fromJson(response);
  }

  // Enregistrer doctorant (admin enregistre INE sans mot de passe)
  Future<UtilisateurModel> enregistrerDoctorant({
    required String nom,
    required String prenom,
    required String email,
    required String ine,
    String? telephone,
    String? ecoleDoctorale,
  }) async {
    final response = await _supabase.from('utilisateurs').insert({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'ine': ine,
      'role': 'doctorant',
      'telephone': telephone,
      'actif': true,
      'ecole_doctorale': ecoleDoctorale,
    }).select().single();
    return UtilisateurModel.fromJson(response);
  }

  // Activer / Désactiver un compte
  Future<void> toggleActifUtilisateur(
      String id, bool actif) async {
    await _supabase
        .from('utilisateurs')
        .update({'actif': actif})
        .eq('id', id);
  }

  // Modifier utilisateur
  Future<void> modifierUtilisateur(
      String id, Map<String, dynamic> data) async {
    await _supabase.from('utilisateurs').update(data).eq('id', id);
  }

  // Supprimer utilisateur (soft delete)
  Future<void> supprimerUtilisateur(String id) async {
    await _supabase
        .from('utilisateurs')
        .update({'actif': false})
        .eq('id', id);
  }

  // Rechercher utilisateurs
  Future<List<UtilisateurModel>> rechercherUtilisateurs(
      String query, String role) async {
    final response = await _supabase
        .from('utilisateurs')
        .select()
        .eq('role', role)
        .or('nom.ilike.%$query%,prenom.ilike.%$query%,ine.ilike.%$query%')
        .order('nom');
    return (response as List)
        .map((e) => UtilisateurModel.fromJson(e))
        .toList();
  }

  // ── PROFIL COMPLET DOCTORANT ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getProfilCompletDoctorant(
      String doctorantId) async {
    final results = await Future.wait([
      _supabase.from('utilisateurs').select().eq('id', doctorantId).single(),
      _supabase.from('theses').select().eq('doctorant_id', doctorantId).maybeSingle(),
      _supabase.from('rapports_avancement').select().eq('doctorant_id', doctorantId).order('annee'),
      _supabase.from('manuscrits').select().eq('doctorant_id', doctorantId).maybeSingle(),
      _supabase.from('notifications').select().eq('utilisateur_id', doctorantId).order('created_at', ascending: false).limit(5),
    ]);

    final these = results[1] as Map<String, dynamic>?;
    List<Map<String, dynamic>> rapportsExpertise = [];
    List<Map<String, dynamic>> soutenances = [];

    if (these != null) {
      rapportsExpertise = ((await _supabase
          .from('rapports_expertise')
          .select()
          .eq('these_id', these['id'])) as List)
          .cast<Map<String, dynamic>>();

      soutenances = ((await _supabase
          .from('soutenances')
          .select()
          .eq('these_id', these['id'])) as List)
          .cast<Map<String, dynamic>>();
    }

    return {
      'utilisateur': results[0],
      'these': results[1],
      'rapports': results[2],
      'manuscrit': results[3],
      'notifications': results[4],
      'rapports_expertise': rapportsExpertise,
      'soutenances': soutenances,
    };
  }

  // ── THÈSES ───────────────────────────────────────────────────────────────
  Future<List<TheseModel>> getTheses() async {
    final response = await _supabase
        .from('theses')
        .select()
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => TheseModel.fromJson(e))
        .toList();
  }

  Future<void> updateEtatThese(String theseId, String etat) async {
    await _supabase
        .from('theses')
        .update({'etat': etat})
        .eq('id', theseId);
  }

  // ── MATCHING RAPPORTEURS ─────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getRapporteursSuggeresParScore(
      String theseId) async {
    // Récupérer les mots-clés de la thèse
    final these = await _supabase
        .from('theses')
        .select('mots_cles, specialite')
        .eq('id', theseId)
        .single();

    final motsCles = (these['mots_cles'] as String?)
        ?.split(',')
        .map((e) => e.trim().toLowerCase())
        .toList() ??
        [];
    final specialite =
        (these['specialite'] as String?)?.toLowerCase() ?? '';

    // Récupérer tous les rapporteurs actifs
    final rapporteurs = await _supabase
        .from('utilisateurs')
        .select()
        .eq('role', 'rapporteur')
        .eq('actif', true);

    // Calculer score de compatibilité
    final List<Map<String, dynamic>> scores = [];
    for (final r in rapporteurs as List) {
      final domaine =
      (r['ecole_doctorale'] as String? ?? '').toLowerCase();
      final rNom = '${r['prenom']} ${r['nom']}'.toLowerCase();

      int score = 0;
      for (final mc in motsCles) {
        if (domaine.contains(mc)) score += 3;
        if (rNom.contains(mc)) score += 1;
      }
      if (domaine.contains(specialite)) score += 5;

      scores.add({
        ...Map<String, dynamic>.from(r),
        'score': score,
      });
    }

    scores.sort((a, b) =>
        (b['score'] as int).compareTo(a['score'] as int));
    return scores;
  }

  // Assigner rapporteur à une thèse
  Future<void> assignerRapporteur({
    required String theseId,
    required String rapporteurId,
    required DateTime dateLimite,
  }) async {
    await _supabase.from('rapports_expertise').insert({
      'these_id': theseId,
      'rapporteur_id': rapporteurId,
      'date_limite': dateLimite.toIso8601String().split('T')[0],
      'statut': 'en attente',
    });
  }

  // ── DIRECTEUR EXTERNE ────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getDemandesDirecteurExterne() async {
    final response = await _supabase
        .from('demandes_directeur_externe')
        .select()
        .eq('statut', 'en attente')
        .order('created_at', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<void> validerDirecteurExterne(String demandeId) async {
    await _supabase
        .from('demandes_directeur_externe')
        .update({'statut': 'valide'})
        .eq('id', demandeId);
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

  Future<void> programmerSoutenance({
    required String theseId,
    required String date,
    required String heure,
    required String lieu,
    required String presidentJury,
  }) async {
    await _supabase.from('soutenances').insert({
      'these_id': theseId,
      'date_soutenance': date,
      'heure': heure,
      'lieu': lieu,
      'president_jury': presidentJury,
    });
  }

  // ── NOTIFICATIONS ────────────────────────────────────────────────────────
  Future<void> envoyerNotification({
    required String titre,
    required String message,
    String? cible, // 'tous', 'doctorants', 'directeurs', etc.
    String? utilisateurId, // si cible = un utilisateur précis
    String? ecoleDoctorale,
  }) async {
    List<String> destinataires = [];

    if (utilisateurId != null) {
      destinataires = [utilisateurId];
    } else if (cible == 'tous') {
      final users = await _supabase.from('utilisateurs').select('id');
      destinataires = (users as List).map((u) => u['id'] as String).toList();
    } else if (cible != null) {
      var query = _supabase.from('utilisateurs').select('id').eq('role', cible);
      if (ecoleDoctorale != null) {
        query = query.eq('ecole_doctorale', ecoleDoctorale);
      }
      final users = await query;
      destinataires = (users as List).map((u) => u['id'] as String).toList();
    }

    // Insérer une notification pour chaque destinataire
    final inserts = destinataires.map((id) => {
      'utilisateur_id': id,
      'titre': titre,
      'message': message,
      'lu': false,
    }).toList();

    if (inserts.isNotEmpty) {
      await _supabase.from('notifications').insert(inserts);
    }
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
        .update({'statut': 'valide'})
        .eq('id', manuscritId);
  }

  Future<void> rejeterManuscrit(String manuscritId) async {
    await _supabase
        .from('manuscrits')
        .update({'statut': 'rejete'})
        .eq('id', manuscritId);
  }
}