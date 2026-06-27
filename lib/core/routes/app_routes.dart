import 'package:go_router/go_router.dart';
import '../../screens/directeur_ed/cas_exception_directeur_ed_screen.dart';
import '../../screens/directeur_ed/dashboard_directeur_ed_screen.dart';
import '../../screens/directeur_ed/profil_directeur_ed_screen.dart';
import '../../screens/directeur_ed/prorogations_directeur_ed_screen.dart';
import '../../screens/directeur_ed/statistiques_directeur_ed_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/create_account_screen.dart';
// Doctorant
import '../../screens/doctorant/dashboard_doctorant_screen.dart';
import '../../screens/doctorant/these/these_screen.dart';
import '../../screens/doctorant/these/enregistrer_these_screen.dart';
import '../../screens/doctorant/rapports/rapports_screen.dart';
import '../../screens/doctorant/rapports/deposer_rapport_screen.dart';
import '../../screens/doctorant/manuscrit/manuscrit_screen.dart';
import '../../screens/doctorant/notifications/notifications_screen.dart';
import '../../screens/doctorant/opportunites/opportunites_screen.dart';
import '../../screens/doctorant/profil/profil_screen.dart';
// CSI
import '../../screens/csi/dashboard_csi_screen.dart';
import '../../screens/csi/rapports_csi_screen.dart';
import '../../screens/csi/entretien_csi_screen.dart';
import '../../screens/csi/avis_csi_screen.dart';
import '../../screens/csi/signalement_csi_screen.dart';
import '../../screens/csi/profil_csi_screen.dart';
// Directeur
import '../../screens/directeur/dashboard_directeur_screen.dart';
import '../../screens/directeur/doctorants_directeur_screen.dart';
import '../../screens/directeur/rapport_directeur_screen.dart';
import '../../screens/directeur/manuscrit_directeur_screen.dart';
import '../../screens/directeur/profil_directeur_screen.dart';
// Rapporteur

import '../../screens/rapporteur/dashboard_rapporteur_screen.dart';
import '../../screens/rapporteur/manuscrit_rapporteur_screen.dart';
import '../../screens/rapporteur/deposer_rapport_rapporteur_screen.dart';
import '../../screens/rapporteur/profil_rapporteur_screen.dart';
// Admin
import '../../screens/admin/dashboard_admin_screen.dart';
import '../../screens/admin/gestion_doctorants_screen.dart';
import '../../screens/admin/ajouter_utilisateur_screen.dart';
import '../../screens/admin/gestion_directeurs_screen.dart';
import '../../screens/admin/gestion_rapporteurs_screen.dart';
import '../../screens/admin/gestion_csi_screen.dart';
import '../../screens/admin/gestion_theses_screen.dart';
import '../../screens/admin/gestion_soutenances_screen.dart';
import '../../screens/admin/gestion_manuscrits_screen.dart';
import '../../screens/admin/notifications_admin_screen.dart';
import '../../screens/admin/profil_admin_screen.dart';
import '../../screens/admin/envoyer_notification_screen.dart';
import '../../screens/admin/profil_doctorant_admin_screen.dart';
import '../../screens/admin/rapporteurs_matching_screen.dart';
// Placeholder screens
import '../../screens/placeholder_screen.dart';

class AppRoutes {
  // ═══════════════════════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════════════════════
  static const String splash = '/';
  static const String login = '/login';
  static const String createAccount = '/create-account';

  // ═══════════════════════════════════════════════════════════════════════
  // DOCTORANT
  // ═══════════════════════════════════════════════════════════════════════
  static const String dashboard = '/dashboard';
  static const String these = '/these';
  static const String enregistrerThese = '/enregistrer-these';
  static const String rapports = '/rapports';
  static const String deposerRapport = '/deposer-rapport';
  static const String manuscrit = '/manuscrit';
  static const String notifications = '/notifications';
  static const String opportunites = '/opportunites';
  static const String profil = '/profil';


  // ═══════════════════════════════════════════════════════════════════════
  // CSI
  // ═══════════════════════════════════════════════════════════════════════
  static const String dashboardCSI = '/csi/dashboard';
  static const String rapportsCSI = '/csi/rapports';
  static const String entretienCSI = '/csi/entretien';
  static const String avisCSI = '/csi/avis';
  static const String signalementCSI = '/csi/signalement';
  static const String profilCSI = '/csi/profil';
  // ═══════════════════════════════════════════════════════════════════════
// DIRECTEUR DE THÈSE
// ═══════════════════════════════════════════════════════════════════════
  static const String dashboardDirecteur = '/directeur/dashboard';
  static const String doctorantsDirecteur = '/directeur/doctorants';
  static const String rapportDirecteur = '/directeur/rapports';
  static const String manuscritDirecteur = '/directeur/manuscrits';
  static const String profilDirecteur = '/directeur/profil';

  // ═══════════════════════════════════════════════════════════════════════
  // ADMIN — DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════
  static const String dashboardAdmin = '/admin/dashboard';

  // ═══════════════════════════════════════════════════════════════════════
  // ADMIN — GESTION DOCTORANTS
  // ═══════════════════════════════════════════════════════════════════════
  static const String gestionDoctorants = '/admin/doctorants';
  static const String ajouterDoctorant = '/admin/doctorants/ajouter';
  static const String profilDoctorantAdmin = '/admin/doctorants/profil';
  // ═══════════════════════════════════════════════════════════════════════
// RAPPORTEUR
// ═══════════════════════════════════════════════════════════════════════
  static const String dashboardRapporteur = '/rapporteur/dashboard';
  static const String manuscritRapporteur = '/rapporteur/manuscrit';
  static const String deposerRapportRapporteur = '/rapporteur/deposer';
  static const String profilRapporteur = '/rapporteur/profil';
  // ═══════════════════════════════════════════════════════════════════════
// DIRECTEUR ÉCOLE DOCTORALE
// ═══════════════════════════════════════════════════════════════════════
  static const String dashboardDirecteurED = '/directeur-ed/dashboard';
  static const String prorogationsDirecteurED = '/directeur-ed/prorogations';
  static const String casExceptionDirecteurED = '/directeur-ed/cas-exception';
  static const String statistiquesDirecteurED = '/directeur-ed/statistiques';
  static const String profilDirecteurED = '/directeur-ed/profil';

  // ═══════════════════════════════════════════════════════════════════════
  // ADMIN — GESTION DIRECTEURS
  // ═══════════════════════════════════════════════════════════════════════
  static const String gestionDirecteurs = '/admin/directeurs';
  static const String ajouterDirecteur = '/admin/directeurs/ajouter';

  // ═══════════════════════════════════════════════════════════════════════
  // ADMIN — GESTION RAPPORTEURS
  // ═══════════════════════════════════════════════════════════════════════
  static const String gestionRapporteurs = '/admin/rapporteurs';
  static const String ajouterRapporteur = '/admin/rapporteurs/ajouter';
  static const String rapporteursMatching = '/admin/rapporteurs/matching';

  // ═══════════════════════════════════════════════════════════════════════
  // ADMIN — GESTION CSI
  // ═══════════════════════════════════════════════════════════════════════
  static const String gestionCSI = '/admin/csi';
  static const String ajouterCSI = '/admin/csi/ajouter';

  // ═══════════════════════════════════════════════════════════════════════
  // ADMIN — GESTION THÈSES
  // ═══════════════════════════════════════════════════════════════════════
  static const String gestionTheses = '/admin/theses';

  // ═══════════════════════════════════════════════════════════════════════
  // ADMIN — GESTION SOUTENANCES
  // ═══════════════════════════════════════════════════════════════════════
  static const String gestionSoutenances = '/admin/soutenances';

  // ═══════════════════════════════════════════════════════════════════════
  // ADMIN — GESTION MANUSCRITS
  // ═══════════════════════════════════════════════════════════════════════
  static const String gestionManuscrits = '/admin/manuscrits';

  // ═══════════════════════════════════════════════════════════════════════
  // ADMIN — GESTION RAPPORTS ANNUELS
  // ═══════════════════════════════════════════════════════════════════════
  static const String gestionRapports = '/admin/rapports-annuels';

  // ═══════════════════════════════════════════════════════════════════════
  // ADMIN — NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════
  static const String notificationsAdmin = '/admin/notifications';
  static const String envoyerNotification = '/admin/notifications/envoyer';

  // ═══════════════════════════════════════════════════════════════════════
  // ADMIN — PROFIL
  // ═══════════════════════════════════════════════════════════════════════
  static const String profilAdmin = '/admin/profil';

  // ═══════════════════════════════════════════════════════════════════════
  // AUTRES RÔLES (PLACEHOLDERS)
  // ═══════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════
  // ROUTER
  // ═══════════════════════════════════════════════════════════════════════
  static final router = GoRouter(
    initialLocation: splash,
    routes: [
      // ─── AUTH ──────────────────────────────────────────────────────────
      GoRoute(path: splash, builder: (c, s) => const SplashScreen()),
      GoRoute(path: login, builder: (c, s) => const LoginScreen()),
      GoRoute(path: createAccount, builder: (c, s) => const CreateAccountScreen()),

      // ─── DOCTORANT ─────────────────────────────────────────────────────
      GoRoute(path: dashboard, builder: (c, s) => const DashboardDoctorantScreen()),
      GoRoute(path: these, builder: (c, s) => const TheseScreen()),
      GoRoute(path: enregistrerThese, builder: (c, s) => const EnregistrerTheseScreen()),
      GoRoute(path: rapports, builder: (c, s) => const RapportsScreen()),
      GoRoute(path: deposerRapport, builder: (c, s) => const DeposerRapportScreen()),
      GoRoute(path: manuscrit, builder: (c, s) => const ManuscritScreen()),
      GoRoute(path: notifications, builder: (c, s) => const NotificationsScreen()),
      GoRoute(path: opportunites, builder: (c, s) => const OpportunitesScreen()),
      GoRoute(path: profil, builder: (c, s) => const ProfilScreen()),
      // ─── DIRECTEUR ──────────────────────────────────────────────────────────
      GoRoute(path: dashboardDirecteur, builder: (c, s) => const DashboardDirecteurScreen()),
      GoRoute(path: doctorantsDirecteur, builder: (c, s) => const DoctorantsDirecteurScreen()),
      GoRoute(
        path: '$rapportDirecteur/:doctorantId?',
        builder: (c, s) {
          final id = s.pathParameters['doctorantId'];
          return RapportDirecteurScreen(doctorantId: id);
        },
      ),
      GoRoute(
        path: '$manuscritDirecteur/:doctorantId?',
        builder: (c, s) {
          final id = s.pathParameters['doctorantId'];
          return ManuscritDirecteurScreen(doctorantId: id);
        },
      ),
      GoRoute(path: profilDirecteur, builder: (c, s) => const ProfilDirecteurScreen()),

      // ─── CSI ────────────────────────────────────────────────────────────
      GoRoute(path: dashboardCSI, builder: (c, s) => const DashboardCSIScreen()),
      GoRoute(path: rapportsCSI, builder: (c, s) => const RapportsCSIScreen()),
      GoRoute(
        path: '$entretienCSI/:doctorantId?',
        builder: (c, s) {
          final id = s.pathParameters['doctorantId'];
          return EntretienCSIScreen(doctorantId: id);
        },
      ),
      GoRoute(
        path: '$avisCSI/:rapportId?',
        builder: (c, s) {
          final id = s.pathParameters['rapportId'];
          return AvisCSIScreen(rapportId: id);
        },
      ),
      GoRoute(
        path: '$signalementCSI/:doctorantId?',
        builder: (c, s) {
          final id = s.pathParameters['doctorantId'];
          return SignalementCSIScreen(doctorantId: id);
        },
      ),
      GoRoute(path: profilCSI, builder: (c, s) => const ProfilCSIScreen()),

      // ─── RAPPORTEUR ─────────────────────────────────────────────────────────
      GoRoute(path: dashboardRapporteur, builder: (c, s) => const DashboardRapporteurScreen()),
      GoRoute(
        path: '$manuscritRapporteur/:expertiseId',
        builder: (c, s) => ManuscritRapporteurScreen(
          expertiseId: s.pathParameters['expertiseId']!,
        ),
      ),
      GoRoute(path: deposerRapportRapporteur, builder: (c, s) => const DeposerRapportRapporteurScreen()),
      GoRoute(path: profilRapporteur, builder: (c, s) => const ProfilRapporteurScreen()),

      // ─── ADMIN ─────────────────────────────────────────────────────────
      // Dashboard
      GoRoute(path: dashboardAdmin, builder: (c, s) => const DashboardAdminScreen()),

      // Doctorants
      GoRoute(path: gestionDoctorants, builder: (c, s) => const GestionDoctorantsScreen()),
      GoRoute(
        path: ajouterDoctorant,
        builder: (c, s) => const AjouterUtilisateurScreen(role: 'doctorant'),
      ),
      GoRoute(
        path: '$profilDoctorantAdmin/:id',
        builder: (c, s) => ProfilDoctorantAdminScreen(
          doctorantId: s.pathParameters['id']!,
        ),
      ),


      // Directeurs
      GoRoute(path: gestionDirecteurs, builder: (c, s) => const GestionDirecteursScreen()),
      GoRoute(
        path: ajouterDirecteur,
        builder: (c, s) => const AjouterUtilisateurScreen(role: 'directeur'),
      ),

      // ─── DIRECTEUR ÉCOLE DOCTORALE ─────────────────────────────────────────
      GoRoute(path: dashboardDirecteurED, builder: (c, s) => const DashboardDirecteurEDScreen()),
      GoRoute(path: prorogationsDirecteurED, builder: (c, s) => const ProrogationsDirecteurEDScreen()),
      GoRoute(path: casExceptionDirecteurED, builder: (c, s) => const CasExceptionDirecteurEDScreen()),
      GoRoute(path: statistiquesDirecteurED, builder: (c, s) => const StatistiquesDirecteurEDScreen()),
      GoRoute(path: profilDirecteurED, builder: (c, s) => const ProfilDirecteurEDScreen()),

      // Rapporteurs
      GoRoute(path: gestionRapporteurs, builder: (c, s) => const GestionRapporteursScreen()),
      GoRoute(
        path: ajouterRapporteur,
        builder: (c, s) => const AjouterUtilisateurScreen(role: 'rapporteur'),
      ),
      GoRoute(
        path: '$rapporteursMatching/:theseId',
        builder: (c, s) => RapporteursMatchingScreen(
          theseId: s.pathParameters['theseId']!,
        ),
      ),

      // CSI Admin
      GoRoute(path: gestionCSI, builder: (c, s) => const GestionCSIScreen()),
      GoRoute(
        path: ajouterCSI,
        builder: (c, s) => const AjouterUtilisateurScreen(role: 'csi'),
      ),

      // Thèses
      GoRoute(path: gestionTheses, builder: (c, s) => const GestionThesesScreen()),

      // Soutenances
      GoRoute(path: gestionSoutenances, builder: (c, s) => const GestionSoutenancesScreen()),

      // Manuscrits
      GoRoute(path: gestionManuscrits, builder: (c, s) => const GestionManuscritsScreen()),

      // Rapports Annuels
      GoRoute(
        path: gestionRapports,
        builder: (c, s) => const PlaceholderScreen(titre: 'Gestion des Rapports Annuels'),
      ),

      // Notifications
      GoRoute(path: notificationsAdmin, builder: (c, s) => const NotificationsAdminScreen()),
      GoRoute(path: envoyerNotification, builder: (c, s) => const EnvoyerNotificationScreen()),

      // Profil Admin
      GoRoute(path: profilAdmin, builder: (c, s) => const ProfilAdminScreen()),

      // ─── AUTRES RÔLES (PLACEHOLDERS) ──────────────────────────────────
      GoRoute(
        path: dashboardDirecteur,
        builder: (c, s) => const PlaceholderScreen(titre: 'Directeur de Thèse'),
      ),
      GoRoute(
        path: dashboardRapporteur,
        builder: (c, s) => const PlaceholderScreen(titre: 'Rapporteur'),
      ),
    ],
  );
}