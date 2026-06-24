import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';
import '../models/utilisateur_model.dart';
import '../models/these_model.dart';
import '../models/soutenance_model.dart';
import '../models/notification_model.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

// Stats dashboard
final adminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.read(adminServiceProvider).getStatistiques();
});

// Doctorants
final doctorantsProvider = FutureProvider<List<UtilisateurModel>>((ref) async {
  return ref.read(adminServiceProvider).getUtilisateursByRole('doctorant');
});

// Directeurs
final directeursAdminProvider =
FutureProvider<List<UtilisateurModel>>((ref) async {
  return ref.read(adminServiceProvider).getUtilisateursByRole('directeur');
});

// Rapporteurs
final rapporteursAdminProvider =
FutureProvider<List<UtilisateurModel>>((ref) async {
  return ref.read(adminServiceProvider).getUtilisateursByRole('rapporteur');
});

// CSI
final csiAdminProvider = FutureProvider<List<UtilisateurModel>>((ref) async {
  return ref.read(adminServiceProvider).getUtilisateursByRole('csi');
});

// Thèses
final thesesAdminProvider = FutureProvider<List<TheseModel>>((ref) async {
  return ref.read(adminServiceProvider).getTheses();
});

// Soutenances
final soutenancesAdminProvider =
FutureProvider<List<SoutenanceModel>>((ref) async {
  return ref.read(adminServiceProvider).getSoutenances();
});

// Notifications récentes
final notificationsAdminProvider =
FutureProvider<List<NotificationModel>>((ref) async {
  return ref.read(adminServiceProvider).getNotificationsRecentes();
});

// Manuscrits en attente
final manuscritsEnAttenteProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminServiceProvider).getManuscritsEnAttente();
});

// Recherche utilisateurs
final rechercheUtilisateurProvider =
FutureProvider.family<List<UtilisateurModel>, Map<String, String>>(
        (ref, params) async {
      return ref
          .read(adminServiceProvider)
          .rechercherUtilisateurs(params['query'] ?? '', params['role'] ?? '');
    });