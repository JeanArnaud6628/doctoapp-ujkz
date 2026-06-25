import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/utilisateur_model.dart';
import '../models/these_model.dart';
import '../models/soutenance_model.dart';
import '../models/notification_model.dart';
import '../models/rapport_model.dart';
import '../models/historique_model.dart';

class AdminService {
  final _supabase = Supabase.instance.client;

  // ── STATISTIQUES ──────────────────────────────────────────────────────────
  Future<Map<String, int>> getStatistiques() async {
    try {
      final results = await Future.wait([
        _supabase.from('utilisateurs').select('id').eq('role', 'doctorant').eq('actif', true),
        _supabase.from('utilisateurs').select('id').eq('role', 'directeur').eq('actif', true),
        _supabase.from('utilisateurs').select('id').eq('role', 'rapporteur').eq('actif', true),
        _supabase.from('utilisateurs').select('id').eq('role', 'csi').eq('actif', true),
        _supabase.from('theses').select('id').neq('etat', 'soutenue'),
        _supabase.from('soutenances').select('id').eq('statut', 'programmee'),
        _supabase.from('manuscrits').select('id').eq('statut', 'en attente'),
        _supabase.from('rapports_avancement').select('id').eq('statut', 'en attente'),
        _supabase.from('rapports_avancement').select('id').eq('avis_directeur', 'en_attente'),
        _supabase.from('rapports_avancement').select('id').eq('avis_csi', 'en_attente'),
        _supabase.from('rapports_expertise').select('id').eq('statut', 'en_attente'),
      ]);
      return {
        'doctorants': (results[0] as List).length,
        'directeurs': (results[1] as List).length,
        'rapporteurs': (results[2] as List).length,
        'csi': (results[3] as List).length,
        'theses_actives': (results[4] as List).length,
        'soutenances': (results[5] as List).length,
        'manuscrits_attente': (results[6] as List).length,
        'rapports_attente': (results[7] as List).length,
        'quitus_dir_manquants': (results[8] as List).length,
        'avis_csi_manquants': (results[9] as List).length,
        'expertises_attente': (results[10] as List).length,
      };
    } catch (e) {
      return {};
    }
  }

  // ── CYCLE DOCTORAL ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCycleDoctoral() async {
    try {
      final response = await _supabase
          .from('utilisateurs')
          .select(
        'id, nom, prenom, ine, ecole_doctorale, '
            'theses!theses_doctorant_id_fkey('
            'id, titre, etape_actuelle, etat, annee_en_cours, '
            'quitus_directeur, quitus_csi, validation_admin'
            ')',
      )
          .eq('role', 'doctorant')
          .eq('actif', true)
          .order('nom');
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ── MÉTHODE UNIQUE pour mise à jour étape ─────────────────────────────────
  // Met à jour etape_actuelle + enregistre dans historique
  Future<void> updateEtapeThese(String theseId, String etape) async {
    await _supabase
        .from('theses')
        .update({'etape_actuelle': etape})
        .eq('id', theseId);
    await _ajouterHistorique(
      theseId: theseId,
      action: 'Étape mise à jour : $etape',
      typeAction: 'etape',
    );
  }

  // Met à jour uniquement le champ etat (en cours, soutenue, etc.)
  Future<void> updateEtatThese(String theseId, String etat) async {
    await _supabase
        .from('theses')
        .update({'etat': etat})
        .eq('id', theseId);
  }

  // ── UTILISATEURS ──────────────────────────────────────────────────────────
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

  Future<UtilisateurModel?> getUtilisateurById(String id) async {
    try {
      final r = await _supabase
          .from('utilisateurs')
          .select()
          .eq('id', id)
          .single();
      return UtilisateurModel.fromJson(r);
    } catch (_) {
      return null;
    }
  }

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
    String? domainesExpertise,
  }) async {
    final emailAuth = ine != null
        ? '${ine.toLowerCase().replaceAll(' ', '')}@doctoapp.ujkz'
        : email;
    try {
      await _supabase.auth.signUp(
        email: emailAuth,
        password: 'DoctoApp2026!',
      );
    } catch (_) {}

    final response = await _supabase.from('utilisateurs').insert({
      'nom': nom,
      'prenom': prenom,
      'email': emailAuth,
      'ine': ine,
      'role': role,
      'telephone': telephone,
      'actif': true,
      'ecole_doctorale': ecoleDoctorale,
      'grade': grade,
      'specialite': specialite,
      'domaines_expertise': domainesExpertise,
    }).select().single();

    return UtilisateurModel.fromJson(response);
  }

  Future<UtilisateurModel> enregistrerDoctorant({
    required String nom,
    required String prenom,
    required String email,
    required String ine,
    String? telephone,
    String? ecoleDoctorale,
    String? promotion,
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
      'promotion': promotion,
    }).select().single();
    return UtilisateurModel.fromJson(response);
  }

  Future<void> toggleActif(String id, bool actif) async {
    await _supabase
        .from('utilisateurs')
        .update({'actif': actif})
        .eq('id', id);
  }

  Future<void> modifierUtilisateur(
      String id, Map<String, dynamic> data) async {
    await _supabase.from('utilisateurs').update(data).eq('id', id);
  }

  // ── PROFIL COMPLET DOCTORANT ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getProfilComplet(String doctorantId) async {
    final results = await Future.wait([
      _supabase.from('utilisateurs').select().eq('id', doctorantId).single(),
      _supabase.from('theses').select().eq('doctorant_id', doctorantId).maybeSingle(),
      _supabase.from('rapports_avancement').select().eq('doctorant_id', doctorantId).order('annee'),
      _supabase.from('manuscrits').select().eq('doctorant_id', doctorantId).maybeSingle(),
      _supabase.from('notifications').select().eq('utilisateur_id', doctorantId).order('created_at', ascending: false).limit(5),
      _supabase.from('historique').select().eq('utilisateur_id', doctorantId).order('created_at', ascending: false).limit(10),
    ]);

    final these = results[1] as Map<String, dynamic>?;
    List<Map<String, dynamic>> expertises = [];
    List<Map<String, dynamic>> soutenances = [];
    List<Map<String, dynamic>> affectationsCsi = [];

    if (these != null) {
      expertises = ((await _supabase
          .from('rapports_expertise')
          .select()
          .eq('these_id', these['id'])) as List)
          .cast<Map<String, dynamic>>();

      soutenances = ((await _supabase
          .from('soutenances')
          .select()
          .eq('these_id', these['id'])) as List)
          .cast<Map<String, dynamic>>();

      try {
        affectationsCsi = ((await _supabase
            .from('affectations_csi')
            .select('*, utilisateurs(nom, prenom, grade)')
            .eq('these_id', these['id'])
            .eq('actif', true)) as List)
            .cast<Map<String, dynamic>>();
      } catch (_) {}
    }

    return {
      'utilisateur': results[0],
      'these': these,
      'rapports': results[2],
      'manuscrit': results[3],
      'notifications': results[4],
      'historique': results[5],
      'expertises': expertises,
      'soutenances': soutenances,
      'csi': affectationsCsi,
    };
  }

  // ── DIRECTEURS AVEC STATS ─────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getDirecteursAvecStats() async {
    final directeurs = await _supabase
        .from('utilisateurs')
        .select()
        .eq('role', 'directeur')
        .order('nom');

    final List<Map<String, dynamic>> result = [];
    for (final d in directeurs as List) {
      final theses = await _supabase
          .from('theses')
          .select('id, etat')
          .eq('directeur_id', d['id']);

      result.add({
        ...Map<String, dynamic>.from(d),
        'nb_doctorants': (theses as List).length,
      });
    }
    return result;
  }

  // ── CSI AVEC STATS ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCSIAvecStats() async {
    final csi = await _supabase
        .from('utilisateurs')
        .select()
        .eq('role', 'csi')
        .order('nom');

    final List<Map<String, dynamic>> result = [];
    for (final c in csi as List) {
      try {
        final affectations = await _supabase
            .from('affectations_csi')
            .select('id')
            .eq('csi_id', c['id'])
            .eq('actif', true);
        result.add({
          ...Map<String, dynamic>.from(c),
          'nb_doctorants': (affectations as List).length,
          'nb_avis_donnes': 0,
        });
      } catch (_) {
        result.add({
          ...Map<String, dynamic>.from(c),
          'nb_doctorants': 0,
          'nb_avis_donnes': 0,
        });
      }
    }
    return result;
  }

  Future<void> affecterCSI(String theseId, String csiId) async {
    await _supabase.from('affectations_csi').insert({
      'these_id': theseId,
      'csi_id': csiId,
      'actif': true,
    });
    await _ajouterHistorique(
      theseId: theseId,
      action: 'CSI affecté',
      typeAction: 'affectation',
    );
    await updateEtapeThese(theseId, 'csi_affecte');
  }

  // ── RAPPORTEURS AVEC STATS ET MATCHING ───────────────────────────────────
  Future<List<Map<String, dynamic>>> getRapporteursAvecStats() async {
    final rapporteurs = await _supabase
        .from('utilisateurs')
        .select()
        .eq('role', 'rapporteur')
        .eq('actif', true)
        .order('nom');

    final List<Map<String, dynamic>> result = [];
    for (final r in rapporteurs as List) {
      final expertises = await _supabase
          .from('rapports_expertise')
          .select('id, statut')
          .eq('rapporteur_id', r['id']);

      final expertisesList = expertises as List;
      final enCours =
          expertisesList.where((e) => e['statut'] == 'en_attente').length;
      final termines =
          expertisesList.where((e) => e['statut'] == 'depose').length;

      result.add({
        ...Map<String, dynamic>.from(r),
        'nb_total': expertisesList.length,
        'nb_en_cours': enCours,
        'nb_termines': termines,
        'est_libre': enCours == 0,
      });
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getMatchingRapporteurs(
      String theseId) async {
    final these = await _supabase
        .from('theses')
        .select('mots_cles, specialite, titre')
        .eq('id', theseId)
        .single();

    final motsCles = (these['mots_cles'] as String? ?? '')
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    final specialite = (these['specialite'] as String? ?? '').toLowerCase();

    final rapporteurs = await _supabase
        .from('utilisateurs')
        .select()
        .eq('role', 'rapporteur')
        .eq('actif', true);

    final List<Map<String, dynamic>> scores = [];
    for (final r in rapporteurs as List) {
      final domaine =
      (r['domaines_expertise'] as String? ?? '').toLowerCase();
      final specialiteR = (r['specialite'] as String? ?? '').toLowerCase();

      int score = 0;
      for (final mc in motsCles) {
        if (domaine.contains(mc)) score += 3;
        if (specialiteR.contains(mc)) score += 2;
      }
      if (domaine.contains(specialite)) score += 5;
      if (specialiteR.contains(specialite)) score += 4;

      final total = motsCles.length * 3 + 5;
      final pct =
      total > 0 ? (score / total * 100).clamp(0, 100).round() : 0;

      scores.add({
        ...Map<String, dynamic>.from(r),
        'score': score,
        'pourcentage': pct,
      });
    }
    scores.sort(
            (a, b) => (b['pourcentage'] as int).compareTo(a['pourcentage'] as int));
    return scores;
  }

  Future<void> assignerRapporteur({
    required String theseId,
    required String rapporteurId,
    required DateTime dateLimite,
  }) async {
    final these = await _supabase
        .from('theses')
        .select('quitus_directeur, quitus_csi')
        .eq('id', theseId)
        .single();

    if (these['quitus_directeur'] != true) {
      throw Exception(
          'Le quitus du directeur est requis avant d\'affecter un rapporteur.');
    }
    if (these['quitus_csi'] != true) {
      throw Exception(
          'Le quitus du CSI est requis avant d\'affecter un rapporteur.');
    }

    await _supabase.from('rapports_expertise').insert({
      'these_id': theseId,
      'rapporteur_id': rapporteurId,
      'date_limite': dateLimite.toIso8601String().split('T')[0],
      'statut': 'en_attente',
    });

    await updateEtapeThese(theseId, 'rapporteurs_affectes');
    await _ajouterHistorique(
      theseId: theseId,
      action: 'Rapporteur assigné',
      typeAction: 'affectation',
    );
  }

  // ── RAPPORTS ANNUELS ──────────────────────────────────────────────────────
  Future<List<RapportModel>> getRapportsAvancement(
      {String? statut}) async {
    var query = _supabase.from('rapports_avancement').select();
    if (statut != null) query = query.eq('statut', statut);
    final response =
    await query.order('date_depot', ascending: false);
    return (response as List)
        .map((e) => RapportModel.fromJson(e))
        .toList();
  }

  Future<void> validerQuitusDirecteur(String rapportId) async {
    await _supabase.from('rapports_avancement').update({
      'avis_directeur': 'favorable',
      'avis_directeur_date': DateTime.now().toIso8601String(),
    }).eq('id', rapportId);
  }

  Future<void> validerAvisCsi(String rapportId) async {
    await _supabase.from('rapports_avancement').update({
      'avis_csi': 'favorable',
      'avis_csi_date': DateTime.now().toIso8601String(),
    }).eq('id', rapportId);
  }

  // ── MANUSCRITS ────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getManuscrits(
      {String? statut}) async {
    var query = _supabase.from('manuscrits').select();
    if (statut != null) query = query.eq('statut', statut);
    final response =
    await query.order('created_at', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<void> validerManuscrit(
      String manuscritId, String theseId) async {
    await _supabase.from('manuscrits').update({
      'statut': 'valide',
      'validation_admin': true,
      'validation_admin_date': DateTime.now().toIso8601String(),
    }).eq('id', manuscritId);

    if (theseId.isNotEmpty) {
      await updateEtapeThese(theseId, 'manuscrit_depose');
      await _ajouterHistorique(
        theseId: theseId,
        action: 'Manuscrit validé par l\'administration',
        typeAction: 'validation',
      );
    }
  }

  Future<void> rejeterManuscrit(String manuscritId) async {
    await _supabase
        .from('manuscrits')
        .update({'statut': 'rejete'})
        .eq('id', manuscritId);
  }

  // ── THÈSES ────────────────────────────────────────────────────────────────
  Future<List<TheseModel>> getTheses(
      {String? etat, String? etape}) async {
    var query = _supabase.from('theses').select();
    if (etat != null) query = query.eq('etat', etat);
    if (etape != null) query = query.eq('etape_actuelle', etape);
    final response =
    await query.order('created_at', ascending: false);
    return (response as List)
        .map((e) => TheseModel.fromJson(e))
        .toList();
  }

  // ── SOUTENANCES ───────────────────────────────────────────────────────────
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
      'statut': 'programmee',
    });
    await updateEtapeThese(theseId, 'soutenance_programmee');
    await _ajouterHistorique(
      theseId: theseId,
      action: 'Soutenance programmée le $date',
      typeAction: 'soutenance',
    );
  }

  // ── ALERTES ───────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAlertesActives() async {
    try {
      final response =
      await _supabase.from('vue_alertes_actives').select();
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ── HISTORIQUE ────────────────────────────────────────────────────────────
  Future<List<HistoriqueModel>> getHistorique(
      {String? theseId}) async {
    var query = _supabase.from('historique').select();
    if (theseId != null) query = query.eq('these_id', theseId);
    final response = await query
        .order('created_at', ascending: false)
        .limit(50);
    return (response as List)
        .map((e) => HistoriqueModel.fromJson(e))
        .toList();
  }

  Future<void> _ajouterHistorique({
    String? theseId,
    String? utilisateurId,
    required String action,
    String? details,
    String? typeAction,
  }) async {
    try {
      await _supabase.from('historique').insert({
        'these_id': theseId,
        'utilisateur_id': utilisateurId,
        'action': action,
        'details': details,
        'type_action': typeAction,
        'acteur_id': _supabase.auth.currentUser?.id,
      });
    } catch (_) {}
  }

  // ── NOTIFICATIONS ─────────────────────────────────────────────────────────
  Future<void> envoyerNotification({
    required String titre,
    required String message,
    String? cible,
    String? utilisateurId,
    String? ecoleDoctorale,
  }) async {
    List<String> destinataires = [];

    if (utilisateurId != null) {
      destinataires = [utilisateurId];
    } else if (cible == 'tous') {
      final users = await _supabase
          .from('utilisateurs')
          .select('id')
          .eq('actif', true);
      destinataires =
          (users as List).map((u) => u['id'] as String).toList();
    } else if (cible != null) {
      var query = _supabase
          .from('utilisateurs')
          .select('id')
          .eq('role', cible)
          .eq('actif', true);
      if (ecoleDoctorale != null) {
        query = query.eq('ecole_doctorale', ecoleDoctorale);
      }
      final users = await query;
      destinataires =
          (users as List).map((u) => u['id'] as String).toList();
    }

    if (destinataires.isNotEmpty) {
      await _supabase.from('notifications').insert(
        destinataires
            .map((id) => {
          'utilisateur_id': id,
          'titre': titre,
          'message': message,
          'lu': false,
        })
            .toList(),
      );
    }

    await _ajouterHistorique(
      action: 'Notification envoyée : $titre',
      typeAction: 'notification',
    );
  }

  Future<List<NotificationModel>> getNotificationsRecentes() async {
    final response = await _supabase
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(20);
    return (response as List)
        .map((e) => NotificationModel.fromJson(e))
        .toList();
  }

  // ── DEMANDES DIRECTEUR EXTERNE ────────────────────────────────────────────
  Future<List<Map<String, dynamic>>>
  getDemandesDirecteurExterne() async {
    try {
      final response = await _supabase
          .from('demandes_directeur_externe')
          .select()
          .eq('statut', 'en_attente')
          .order('created_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> validerDirecteurExterne(String demandeId) async {
    await _supabase.from('demandes_directeur_externe').update({
      'statut': 'valide',
      'traite_par': _supabase.auth.currentUser?.id,
      'date_traitement': DateTime.now().toIso8601String(),
    }).eq('id', demandeId);
  }

  // ── SUPPRESSION SOFT ──────────────────────────────────────────────────────
  Future<void> supprimerUtilisateur(String id) async {
    await _supabase
        .from('utilisateurs')
        .update({'actif': false})
        .eq('id', id);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES AJOUTÉES POUR LA COMPATIBILITÉ AVEC LES ÉCRANS EXISTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  // ── ALIAS POUR getProfilComplet ──────────────────────────────────────────
  // Garde la compatibilité avec l'ancien nom
  Future<Map<String, dynamic>> getProfilCompletDoctorant(String doctorantId) {
    return getProfilComplet(doctorantId);
  }

  // ── ALIAS POUR toggleActif ───────────────────────────────────────────────
  // Garde la compatibilité avec l'ancien nom
  Future<void> toggleActifUtilisateur(String id, bool actif) {
    return toggleActif(id, actif);
  }

  // ── ALIAS POUR getMatchingRapporteurs ────────────────────────────────────
  // Garde la compatibilité avec l'ancien nom
  Future<List<Map<String, dynamic>>> getRapporteursSuggeresParScore(
      String theseId) {
    return getMatchingRapporteurs(theseId);
  }

  // ── VALIDER MANUSCRIT (version avec 1 paramètre) ────────────────────────
  // Pour les appels qui ne passent pas theseId
  Future<void> validerManuscritSimple(String manuscritId) async {
    await _supabase
        .from('manuscrits')
        .update({'statut': 'valide'})
        .eq('id', manuscritId);
  }

// ── VALIDER MANUSCRIT (version avec 2 paramètres) ────────────────────────
// Pour les appels qui passent theseId (surcharge)
// La méthode existe déjà plus haut avec 2 paramètres
// On garde la signature pour compatibilité
// Future<void> validerManuscrit(String manuscritId, String theseId)
// existe déjà dans le code plus haut

// ── MÉTHODE DE COMPATIBILITÉ POUR LE MATCHING ───────────────────────────
// Si un écran appelle getRapporteursSuggeresParScore avec un paramètre
// déjà géré via l'alias ci-dessus
}