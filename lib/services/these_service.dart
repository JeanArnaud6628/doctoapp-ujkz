import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/these_model.dart';
import '../models/rapport_model.dart';
import '../models/manuscrit_model.dart';
import '../models/notification_model.dart';

class TheseService {
  final _supabase = Supabase.instance.client;

  // Récupérer la thèse du doctorant
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

  // Enregistrer un sujet de thèse
  Future<TheseModel?> enregistrerThese({
    required String doctorantId,
    required String titre,
    required String specialite,
    required String resume,
    String? motsCles,
    String? directeurId,
    String? protocoleUrl,
  }) async {
    final response = await _supabase.from('theses').insert({
      'doctorant_id': doctorantId,
      'titre': titre,
      'specialite': specialite,
      'resume': resume,
      'mots_cles': motsCles,
      'directeur_id': directeurId,
      'protocole_url': protocoleUrl,
      'etat': 'enregistree',
    }).select().single();
    return TheseModel.fromJson(response);
  }

  // Mettre à jour la thèse
  Future<void> updateThese(String theseId, Map<String, dynamic> data) async {
    await _supabase.from('theses').update(data).eq('id', theseId);
  }

  // Récupérer les rapports du doctorant
  Future<List<RapportModel>> getRapports(String doctorantId) async {
    final response = await _supabase
        .from('rapports_avancement')
        .select()
        .eq('doctorant_id', doctorantId)
        .order('annee', ascending: false);
    return (response as List).map((e) => RapportModel.fromJson(e)).toList();
  }

  // Déposer un rapport
  Future<RapportModel?> deposerRapport({
    required String doctorantId,
    required int annee,
    required String titre,
    String? fichierPdf,
  }) async {
    final response = await _supabase.from('rapports_avancement').insert({
      'doctorant_id': doctorantId,
      'annee': annee,
      'titre': titre,
      'fichier_pdf': fichierPdf,
      'statut': 'en attente',
    }).select().single();
    return RapportModel.fromJson(response);
  }

  // Récupérer le manuscrit
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

  // Déposer le manuscrit
  Future<ManuscritModel?> deposerManuscrit({
    required String doctorantId,
    required String titre,
    String? fichierPdf,
  }) async {
    final response = await _supabase.from('manuscrits').insert({
      'doctorant_id': doctorantId,
      'titre': titre,
      'fichier_pdf': fichierPdf,
      'statut': 'en attente',
    }).select().single();
    return ManuscritModel.fromJson(response);
  }

  // Récupérer les notifications
  Future<List<NotificationModel>> getNotifications(
      String utilisateurId) async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('utilisateur_id', utilisateurId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => NotificationModel.fromJson(e))
        .toList();
  }

  // Marquer notification comme lue
  Future<void> marquerNotificationLue(String notifId) async {
    await _supabase
        .from('notifications')
        .update({'lu': true}).eq('id', notifId);
  }

  // Récupérer les directeurs disponibles
  Future<List<Map<String, dynamic>>> getDirecteurs() async {
    final response = await _supabase
        .from('utilisateurs')
        .select('id, nom, prenom, role')
        .eq('role', 'directeur');
    return (response as List).cast<Map<String, dynamic>>();
  }
}