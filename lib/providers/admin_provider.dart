import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';
import '../models/utilisateur_model.dart';
import '../models/these_model.dart';
import '../models/soutenance_model.dart';
import '../models/notification_model.dart';
import '../models/rapport_model.dart';
import '../models/historique_model.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

// Stats
final adminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.read(adminServiceProvider).getStatistiques();
});

// Cycle doctoral
final cycleDoctoral = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminServiceProvider).getCycleDoctoral();
});

// Utilisateurs par rôle
final doctorantsProvider = FutureProvider<List<UtilisateurModel>>((ref) async {
  return ref.read(adminServiceProvider).getUtilisateursByRole('doctorant');
});
final directeursAdminProvider = FutureProvider<List<UtilisateurModel>>((ref) async {
  return ref.read(adminServiceProvider).getUtilisateursByRole('directeur');
});
final rapporteursAdminProvider = FutureProvider<List<UtilisateurModel>>((ref) async {
  return ref.read(adminServiceProvider).getUtilisateursByRole('rapporteur');
});
final csiAdminProvider = FutureProvider<List<UtilisateurModel>>((ref) async {
  return ref.read(adminServiceProvider).getUtilisateursByRole('csi');
});

// Avec stats
final directeursAvecStats = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminServiceProvider).getDirecteursAvecStats();
});
final csiAvecStats = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminServiceProvider).getCSIAvecStats();
});
final rapporteursAvecStats = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminServiceProvider).getRapporteursAvecStats();
});

// Thèses
final thesesAdminProvider = FutureProvider<List<TheseModel>>((ref) async {
  return ref.read(adminServiceProvider).getTheses();
});

// Rapports
final rapportsAttenteProvider = FutureProvider<List<RapportModel>>((ref) async {
  return ref.read(adminServiceProvider).getRapportsAvancement(statut: 'en attente');
});
final tousRapportsProvider = FutureProvider<List<RapportModel>>((ref) async {
  return ref.read(adminServiceProvider).getRapportsAvancement();
});

// Manuscrits
final manuscritsEnAttenteProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminServiceProvider).getManuscrits(statut: 'en attente');
});
final tousManuscritsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminServiceProvider).getManuscrits();
});

// Soutenances
final soutenancesAdminProvider = FutureProvider<List<SoutenanceModel>>((ref) async {
  return ref.read(adminServiceProvider).getSoutenances();
});

// Notifications
final notificationsAdminProvider = FutureProvider<List<NotificationModel>>((ref) async {
  return ref.read(adminServiceProvider).getNotificationsRecentes();
});

// Alertes
final alertesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminServiceProvider).getAlertesActives();
});

// Historique
final historiqueProvider = FutureProvider<List<HistoriqueModel>>((ref) async {
  return ref.read(adminServiceProvider).getHistorique();
});

// Profil doctorant complet
final profilDoctorantProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return ref.read(adminServiceProvider).getProfilComplet(id);
});

// Matching rapporteurs
final matchingRapporteursProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, theseId) async {
  return ref.read(adminServiceProvider).getMatchingRapporteurs(theseId);
});

// Demandes directeur externe
final demandesDirecteurExterneProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminServiceProvider).getDemandesDirecteurExterne();
});

// Recherche
final rechercheUtilisateurProvider = FutureProvider.family<List<UtilisateurModel>, Map<String, String>>((ref, params) async {
  return ref.read(adminServiceProvider).rechercherUtilisateurs(params['query'] ?? '', params['role'] ?? '');
});