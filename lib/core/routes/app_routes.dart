import 'package:go_router/go_router.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/create_account_screen.dart';
import '../../screens/doctorant/dashboard_doctorant_screen.dart';
import '../../screens/doctorant/these/these_screen.dart';
import '../../screens/doctorant/these/enregistrer_these_screen.dart';
import '../../screens/doctorant/rapports/rapports_screen.dart';
import '../../screens/doctorant/rapports/deposer_rapport_screen.dart';
import '../../screens/doctorant/manuscrit/manuscrit_screen.dart';
import '../../screens/doctorant/notifications/notifications_screen.dart';
import '../../screens/doctorant/opportunites/opportunites_screen.dart';
import '../../screens/doctorant/profil/profil_screen.dart';
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

class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String createAccount = '/create-account';
  // Doctorant
  static const String dashboard = '/dashboard';
  static const String these = '/these';
  static const String enregistrerThese = '/enregistrer-these';
  static const String rapports = '/rapports';
  static const String deposerRapport = '/deposer-rapport';
  static const String manuscrit = '/manuscrit';
  static const String notifications = '/notifications';
  static const String opportunites = '/opportunites';
  static const String profil = '/profil';
  // Admin
  static const String dashboardAdmin = '/admin/dashboard';
  static const String gestionDoctorants = '/admin/doctorants';
  static const String ajouterDoctorant = '/admin/doctorants/ajouter';
  static const String gestionDirecteurs = '/admin/directeurs';
  static const String ajouterDirecteur = '/admin/directeurs/ajouter';
  static const String gestionRapporteurs = '/admin/rapporteurs';
  static const String ajouterRapporteur = '/admin/rapporteurs/ajouter';
  static const String gestionCSI = '/admin/csi';
  static const String ajouterCSI = '/admin/csi/ajouter';
  static const String gestionTheses = '/admin/theses';
  static const String gestionSoutenances = '/admin/soutenances';
  static const String gestionManuscrits = '/admin/manuscrits';
  static const String notificationsAdmin = '/admin/notifications';
  static const String profilAdmin = '/admin/profil';

  static final router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(path: splash, builder: (c, s) => const SplashScreen()),
      GoRoute(path: login, builder: (c, s) => const LoginScreen()),
      GoRoute(path: createAccount, builder: (c, s) => const CreateAccountScreen()),
      GoRoute(path: dashboard, builder: (c, s) => const DashboardDoctorantScreen()),
      GoRoute(path: these, builder: (c, s) => const TheseScreen()),
      GoRoute(path: enregistrerThese, builder: (c, s) => const EnregistrerTheseScreen()),
      GoRoute(path: rapports, builder: (c, s) => const RapportsScreen()),
      GoRoute(path: deposerRapport, builder: (c, s) => const DeposerRapportScreen()),
      GoRoute(path: manuscrit, builder: (c, s) => const ManuscritScreen()),
      GoRoute(path: notifications, builder: (c, s) => const NotificationsScreen()),
      GoRoute(path: opportunites, builder: (c, s) => const OpportunitesScreen()),
      GoRoute(path: profil, builder: (c, s) => const ProfilScreen()),
      // Admin routes
      GoRoute(path: dashboardAdmin, builder: (c, s) => const DashboardAdminScreen()),
      GoRoute(path: gestionDoctorants, builder: (c, s) => const GestionDoctorantsScreen()),
      GoRoute(
        path: ajouterDoctorant,
        builder: (c, s) => const AjouterUtilisateurScreen(role: 'doctorant'),
      ),
      GoRoute(path: gestionDirecteurs, builder: (c, s) => const GestionDirecteursScreen()),
      GoRoute(
        path: ajouterDirecteur,
        builder: (c, s) => const AjouterUtilisateurScreen(role: 'directeur'),
      ),
      GoRoute(path: gestionRapporteurs, builder: (c, s) => const GestionRapporteursScreen()),
      GoRoute(
        path: ajouterRapporteur,
        builder: (c, s) => const AjouterUtilisateurScreen(role: 'rapporteur'),
      ),
      GoRoute(path: gestionCSI, builder: (c, s) => const GestionCSIScreen()),
      GoRoute(
        path: ajouterCSI,
        builder: (c, s) => const AjouterUtilisateurScreen(role: 'csi'),
      ),
      GoRoute(path: gestionTheses, builder: (c, s) => const GestionThesesScreen()),
      GoRoute(path: gestionSoutenances, builder: (c, s) => const GestionSoutenancesScreen()),
      GoRoute(path: gestionManuscrits, builder: (c, s) => const GestionManuscritsScreen()),
      GoRoute(path: notificationsAdmin, builder: (c, s) => const NotificationsAdminScreen()),
      GoRoute(path: profilAdmin, builder: (c, s) => const ProfilAdminScreen()),
    ],
  );
}