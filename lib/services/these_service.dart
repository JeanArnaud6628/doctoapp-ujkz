import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/these_model.dart';
import '../models/rapport_model.dart';
import '../models/manuscrit_model.dart';
import '../models/notification_model.dart';

class TheseService {
  final _supabase = Supabase.instance.client;

  // ─── THÈSE ────────────────────────────────────────────────────────────────

  Future<TheseModel?> getTheseDoctorant(String doctorantId) async {
    try {
      final response = await _supabase
          .from('theses')
          .select()
          .eq('doctorant_id', doctorantId)
          .maybeSingle();
      if (response == null) return null;
      return TheseModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<TheseModel?> enregistrerThese({
    required String doctorantId,
    required String titre,
    required String specialite,
    required String resume,
    String? motsCles,
    String? directeurId,
  }) async {
    final response = await _supabase.from('theses').insert({
      'doctorant_id': doctorantId,
      'titre': titre,
      'specialite': specialite,
      'resume': resume,
      'mots_cles': motsCles,
      'directeur_id': directeurId,
      'etat': 'enregistree',
      'etape_actuelle': 'enregistree',
      'annee_en_cours': 1,
      'quitus_directeur': false,
      'quitus_csi': false,
      'validation_admin': false,
    }).select().single();

    await _ajouterNotification(
      utilisateurId: doctorantId,
      titre: 'Sujet de thèse enregistré',
      message: 'Votre sujet de thèse a été enregistré avec succès.',
    );

    return TheseModel.fromJson(response);
  }

  Future<void> updateThese(String theseId, Map<String, dynamic> data) async {
    await _supabase.from('theses').update(data).eq('id', theseId);
  }

  // ─── RAPPORTS ─────────────────────────────────────────────────────────────

  Future<List<RapportModel>> getRapports(String doctorantId) async {
    final response = await _supabase
        .from('rapports_avancement')
        .select()
        .eq('doctorant_id', doctorantId)
        .order('annee', ascending: false);
    return (response as List).map((e) => RapportModel.fromJson(e)).toList();
  }

  Future<RapportModel?> deposerRapport({
    required String doctorantId,
    required int annee,
    required String titre,
    String? fichierPdf,
  }) async {
    final existant = await _supabase
        .from('rapports_avancement')
        .select()
        .eq('doctorant_id', doctorantId)
        .eq('annee', annee)
        .maybeSingle();

    if (existant != null) {
      throw Exception('Un rapport pour l\'année $annee existe déjà.');
    }

    final these = await _supabase
        .from('theses')
        .select('id')
        .eq('doctorant_id', doctorantId)
        .maybeSingle();

    final response = await _supabase.from('rapports_avancement').insert({
      'doctorant_id': doctorantId,
      'annee': annee,
      'titre': titre,
      'fichier_pdf': fichierPdf,
      'statut': 'en attente',
      'avis_directeur': 'en_attente',
      'avis_csi': 'en_attente',
      'these_id': these?['id'],
    }).select().single();

    await _ajouterNotification(
      utilisateurId: doctorantId,
      titre: 'Rapport annuel déposé',
      message: 'Votre rapport d\'avancement Année $annee a été déposé.',
    );

    if (these != null) {
      final theseComplet = await _supabase
          .from('theses')
          .select('directeur_id')
          .eq('id', these['id'])
          .maybeSingle();

      if (theseComplet != null && theseComplet['directeur_id'] != null) {
        await _ajouterNotification(
          utilisateurId: theseComplet['directeur_id'],
          titre: 'Nouveau rapport annuel à valider',
          message: 'Le doctorant a déposé son rapport d\'avancement Année $annee.',
        );
      }
    }

    return RapportModel.fromJson(response);
  }

  Future<void> updateRapportAvisDirecteur(String rapportId, String avis) async {
    await _supabase
        .from('rapports_avancement')
        .update({'avis_directeur': avis})
        .eq('id', rapportId);
  }

  Future<void> updateRapportAvisCsi(String rapportId, String avis) async {
    await _supabase
        .from('rapports_avancement')
        .update({'avis_csi': avis})
        .eq('id', rapportId);
  }

  // ─── MANUSCRIT ────────────────────────────────────────────────────────────

  Future<ManuscritModel?> getManuscrit(String doctorantId) async {
    try {
      final response = await _supabase
          .from('manuscrits')
          .select()
          .eq('doctorant_id', doctorantId)
          .maybeSingle();
      if (response == null) return null;
      return ManuscritModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<ManuscritModel?> deposerManuscrit({
    required String doctorantId,
    required String titre,
    String? fichierPdf,
  }) async {
    final these = await _supabase
        .from('theses')
        .select('id')
        .eq('doctorant_id', doctorantId)
        .maybeSingle();

    final response = await _supabase.from('manuscrits').insert({
      'doctorant_id': doctorantId,
      'titre': titre,
      'fichier_pdf': fichierPdf,
      'statut': 'en attente',
      'these_id': these?['id'],
    }).select().single();

    if (these != null) {
      await _supabase
          .from('theses')
          .update({
        'etape_actuelle': 'manuscrit_depose',
        'etat': 'en_instruction',
      })
          .eq('id', these['id']);
    }

    await _ajouterNotification(
      utilisateurId: doctorantId,
      titre: 'Manuscrit déposé',
      message: 'Votre manuscrit final a été déposé. En attente de validation.',
    );

    return ManuscritModel.fromJson(response);
  }

  // ─── NOTIFICATIONS ────────────────────────────────────────────────────────

  Future<List<NotificationModel>> getNotifications(String utilisateurId) async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('utilisateur_id', utilisateurId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => NotificationModel.fromJson(e))
        .toList();
  }

  Future<void> marquerNotificationLue(String notifId) async {
    await _supabase
        .from('notifications')
        .update({'lu': true})
        .eq('id', notifId);
  }

  // ─── DIRECTEURS ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getDirecteurs() async {
    final response = await _supabase
        .from('utilisateurs')
        .select('id, nom, prenom, grade, specialite, ecole_doctorale')
        .eq('role', 'directeur')
        .eq('actif', true)
        .order('nom');
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getDirecteursByEcole(String ecole) async {
    final response = await _supabase
        .from('utilisateurs')
        .select('id, nom, prenom, grade, specialite, ecole_doctorale')
        .eq('role', 'directeur')
        .eq('actif', true)
        .eq('ecole_doctorale', ecole)
        .order('nom');
    return (response as List).cast<Map<String, dynamic>>();
  }

  // ─── CYCLE DOCTORAL ──────────────────────────────────────────────────────

  Future<void> updateEtapeThese(String theseId, String etape) async {
    await _supabase
        .from('theses')
        .update({'etape_actuelle': etape})
        .eq('id', theseId);
  }

  Future<void> updateQuitusDirecteur(String theseId, bool valide) async {
    await _supabase
        .from('theses')
        .update({'quitus_directeur': valide})
        .eq('id', theseId);
  }

  Future<void> updateQuitusCsi(String theseId, bool valide) async {
    await _supabase
        .from('theses')
        .update({'quitus_csi': valide})
        .eq('id', theseId);
  }

  // ─── DEMANDE DIRECTEUR EXTERNE ──────────────────────────────────────────

  Future<void> demanderDirecteurExterne({
    required String theseId,
    required String nom,
    required String prenom,
    required String universite,
    required String grade,
    required String pays,
    required String email,
  }) async {
    await _supabase.from('demandes_directeur_externe').insert({
      'these_id': theseId,
      'nom': nom,
      'prenom': prenom,
      'universite': universite,
      'grade': grade,
      'pays': pays,
      'email': email,
      'statut': 'en_attente',
    });
  }

  // ─── MÉTHODE PRIVÉE ──────────────────────────────────────────────────────

  Future<void> _ajouterNotification({
    required String utilisateurId,
    required String titre,
    required String message,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'utilisateur_id': utilisateurId,
        'titre': titre,
        'message': message,
        'lu': false,
      });
    } catch (_) {}
  }
}