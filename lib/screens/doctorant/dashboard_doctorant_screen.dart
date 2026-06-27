import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/these_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/these_model.dart';
import '../../../models/notification_model.dart';
import '../../../models/utilisateur_model.dart';

class DashboardDoctorantScreen extends ConsumerStatefulWidget {
  const DashboardDoctorantScreen({super.key});

  @override
  ConsumerState<DashboardDoctorantScreen> createState() =>
      _DashboardDoctorantScreenState();
}

class _DashboardDoctorantScreenState
    extends ConsumerState<DashboardDoctorantScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.utilisateur;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theseAsync = ref.watch(theseProvider(user.id));
    final notifsAsync = ref.watch(notificationsProvider(user.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildHeader(user),
          SliverPadding(
            padding: const EdgeInsets.all(14),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                theseAsync.when(
                  data: (these) => _buildStatutCarte(these, user),
                  loading: () => const _LoadingCard(),
                  error: (_, __) => _buildStatutCarte(null, user),
                ),
                const SizedBox(height: 14),
                theseAsync.when(
                  data: (these) => _buildTimeline(these),
                  loading: () => const _LoadingCard(),
                  error: (_, __) => _buildTimeline(null),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 0),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(UtilisateurModel user) {
    final String ine = user.ine ?? 'INE';
    final String ecole = user.ecoleDoctorale ?? 'UJKZ';
    final String promotion = user.promotion ?? 'Non définie';

    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A5C2A), Color(0xFF2E7D42)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bonjour,',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        user.nomComplet,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'INE: $ine  •  $ecole',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Promotion: $promotion',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        user.initiales,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => context.push(AppRoutes.notifications),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUT ACTUEL
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatutCarte(TheseModel? these, UtilisateurModel user) {
    final statutInfo = _calculerStatut(these, user);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statutInfo['color'].withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              statutInfo['icon'],
              color: statutInfo['color'],
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statut du parcours',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGray,
                  ),
                ),
                Text(
                  statutInfo['label'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: statutInfo['color'],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statutInfo['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statutInfo['progress'] ?? '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statutInfo['color'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculerStatut(TheseModel? these, UtilisateurModel user) {
    if (these == null) {
      return {
        'label': 'En attente d\'activation',
        'color': Colors.orange,
        'icon': Icons.pending_actions,
        'progress': '0%',
      };
    }

    final etape = these.etapeActuelle ?? 'enregistree';
    final quitusDir = these.quitusDirecteur ?? false;
    final quitusCsi = these.quitusCsi ?? false;
    final validationAdmin = these.validationAdmin ?? false;

    double progress = 5;
    String label = '';
    Color color = Colors.grey;
    IconData icon = Icons.pending;

    switch (etape) {
      case 'enregistree':
        progress = 5;
        label = 'Sujet enregistré';
        color = Colors.grey;
        icon = Icons.description;
        break;
      case 'directeur_choisi':
        progress = 10;
        label = 'Directeur choisi (en attente validation)';
        color = Colors.orange;
        icon = Icons.person_pin;
        break;
      case 'directeur_valide':
        progress = 15;
        label = 'Directeur validé';
        color = Colors.blue;
        icon = Icons.verified;
        break;
      case 'csi_affecte':
        progress = 20;
        label = 'CSI affecté';
        color = Colors.teal;
        icon = Icons.groups;
        break;
      case 'rapport_annuel_1':
        progress = 30;
        label = 'Rapport annuel 1 en cours';
        color = Colors.orange;
        icon = Icons.assignment;
        break;
      case 'rapport_annuel_1_valide':
        progress = 35;
        label = 'Rapport annuel 1 validé';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rapport_annuel_2':
        progress = 45;
        label = 'Rapport annuel 2 en cours';
        color = Colors.orange;
        icon = Icons.assignment;
        break;
      case 'rapport_annuel_2_valide':
        progress = 50;
        label = 'Rapport annuel 2 validé';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rapport_annuel_3':
        progress = 60;
        label = 'Rapport annuel 3 en cours';
        color = Colors.orange;
        icon = Icons.assignment;
        break;
      case 'rapport_annuel_3_valide':
        progress = 65;
        label = 'Rapport annuel 3 validé';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'manuscrit_depose':
        progress = 70;
        label = 'Manuscrit déposé';
        color = Colors.purple;
        icon = Icons.upload_file;
        break;
      case 'quitus_directeur':
        progress = 75;
        label = quitusDir ? 'Quitus Directeur obtenu' : 'En attente quitus Directeur';
        color = quitusDir ? Colors.green : Colors.orange;
        icon = Icons.check_circle;
        break;
      case 'quitus_csi':
        progress = 80;
        label = quitusCsi ? 'Quitus CSI obtenu' : 'En attente quitus CSI';
        color = quitusCsi ? Colors.green : Colors.orange;
        icon = Icons.check_circle;
        break;
      case 'validation_admin':
        progress = 85;
        label = validationAdmin ? 'Validation admin obtenue' : 'En attente validation admin';
        color = validationAdmin ? Colors.green : Colors.orange;
        icon = Icons.admin_panel_settings;
        break;
      case 'rapporteurs_affectes':
        progress = 90;
        label = 'Rapporteurs affectés';
        color = Colors.indigo;
        icon = Icons.rate_review;
        break;
      case 'evaluation_rapporteurs':
        progress = 92;
        label = 'Évaluation des rapporteurs en cours';
        color = Colors.deepPurple;
        icon = Icons.assessment;
        break;
      case 'soutenance_programmee':
        progress = 95;
        label = 'Soutenance programmée';
        color = Colors.green;
        icon = Icons.event;
        break;
      case 'soutenance_realisee':
        progress = 100;
        label = '🎉 Cycle doctoral terminé !';
        color = Colors.green;
        icon = Icons.celebration;
        break;
      default:
        progress = 5;
        label = 'Sujet enregistré';
        color = Colors.grey;
        icon = Icons.description;
    }

    return {
      'label': label,
      'color': color,
      'icon': icon,
      'progress': '${progress.round()}%',
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIMELINE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTimeline(TheseModel? these) {
    if (these == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'PARCOURS DOCTORAL',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF4A7A4A),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enregistrez votre sujet de thèse pour commencer',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textGray,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.enregistrerThese),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text(
                'Enregistrer mon sujet',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final etapes = _getEtapes(these);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PARCOURS DOCTORAL',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF4A7A4A),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ...etapes.map((e) {
            final isDone = e['statut'] == 'Terminée';
            final isActive = e['statut'] == 'En cours';
            final isBlocked = e['statut'] == 'Bloquée';

            Color bgColor = Colors.white;
            Color borderColor = Colors.grey[200]!;
            Color iconBg = Colors.grey[100]!;
            Color iconColor = Colors.grey;
            Color textColor = AppTheme.textGray;

            if (isDone) {
              bgColor = const Color(0xFFF1F8F1);
              iconBg = AppTheme.primaryColor;
              iconColor = Colors.white;
              borderColor = AppTheme.primaryColor;
              textColor = AppTheme.textDark;
            } else if (isActive) {
              bgColor = const Color(0xFFE8F5E9);
              iconBg = Colors.white;
              iconColor = AppTheme.primaryColor;
              borderColor = AppTheme.primaryColor;
              textColor = AppTheme.textDark;
            } else if (isBlocked) {
              bgColor = const Color(0xFFFFEBEE);
              iconBg = Colors.red.withOpacity(0.1);
              iconColor = Colors.red;
              borderColor = Colors.red;
              textColor = Colors.red;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: isActive ? 1.5 : 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                      border: isActive && !isDone
                          ? Border.all(color: AppTheme.primaryColor, width: 1.5)
                          : null,
                    ),
                    child: Icon(
                      e['icon'],
                      size: 14,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e['label'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        if (e['detail'] != null)
                          Text(
                            e['detail']!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textGray,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFFE8F5E9)
                          : isActive
                          ? const Color(0xFFFFF3E0)
                          : isBlocked
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      e['statut'] ?? 'En attente',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: isDone
                            ? AppTheme.primaryColor
                            : isActive
                            ? const Color(0xFFC84B00)
                            : isBlocked
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTHODES DE GESTION DES ÉTAPES
  // ═══════════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _getEtapes(TheseModel these) {
    final etape = these.etapeActuelle ?? 'enregistree';
    final quitusDir = these.quitusDirecteur ?? false;
    final quitusCsi = these.quitusCsi ?? false;

    final List<Map<String, dynamic>> etapes = [
      {'key': 'activation', 'label': 'Activation du compte', 'icon': Icons.check_circle, 'statut': 'Terminée', 'detail': null},
      {'key': 'choix_directeur', 'label': 'Choix du directeur', 'icon': Icons.person_pin, 'statut': 'En attente', 'detail': null},
      {'key': 'validation_directeur', 'label': 'Validation du directeur', 'icon': Icons.verified, 'statut': 'En attente', 'detail': null},
      {'key': 'csi_affecte', 'label': 'Affectation CSI', 'icon': Icons.groups, 'statut': 'En attente', 'detail': null},
      {'key': 'rapport1', 'label': 'Rapport Annuel 1', 'icon': Icons.assignment, 'statut': 'En attente', 'detail': null},
      {'key': 'rapport2', 'label': 'Rapport Annuel 2', 'icon': Icons.assignment, 'statut': 'En attente', 'detail': null},
      {'key': 'rapport3', 'label': 'Rapport Annuel 3', 'icon': Icons.assignment, 'statut': 'En attente', 'detail': null},
      {'key': 'manuscrit', 'label': 'Dépôt Manuscrit Final', 'icon': Icons.upload_file, 'statut': 'En attente', 'detail': null},
      {'key': 'quitus_dir', 'label': 'Quitus Directeur', 'icon': Icons.check_circle, 'statut': 'En attente', 'detail': quitusDir ? 'Obtenu' : null},
      {'key': 'quitus_csi', 'label': 'Quitus CSI', 'icon': Icons.check_circle, 'statut': 'En attente', 'detail': quitusCsi ? 'Obtenu' : null},
      {'key': 'rapporteurs', 'label': 'Affectation Rapporteurs', 'icon': Icons.rate_review, 'statut': 'En attente', 'detail': null},
      {'key': 'soutenance', 'label': 'Soutenance', 'icon': Icons.event, 'statut': 'En attente', 'detail': null},
    ];

    final etapeKeys = _getEtapeKeys(etape);
    for (final e in etapes) {
      if (etapeKeys.contains(e['key'])) {
        e['statut'] = 'Terminée';
      }
    }

    final currentKey = _getCurrentKey(etape);
    for (final e in etapes) {
      if (e['key'] == currentKey) {
        e['statut'] = 'En cours';
      }
    }

    if (!quitusDir && etape != 'enregistree' && etape != 'directeur_choisi') {
      for (final e in etapes) {
        if (e['key'] == 'quitus_dir') {
          e['statut'] = 'Bloquée';
          e['detail'] = 'En attente du directeur';
        }
      }
    }

    if (!quitusCsi && etape != 'enregistree' && etape != 'directeur_choisi') {
      for (final e in etapes) {
        if (e['key'] == 'quitus_csi') {
          e['statut'] = 'Bloquée';
          e['detail'] = 'En attente du CSI';
        }
      }
    }

    return etapes;
  }

  List<String> _getEtapeKeys(String etape) {
    switch (etape) {
      case 'enregistree':
        return ['activation'];
      case 'directeur_choisi':
        return ['activation', 'choix_directeur'];
      case 'directeur_valide':
        return ['activation', 'choix_directeur', 'validation_directeur'];
      case 'csi_affecte':
        return ['activation', 'choix_directeur', 'validation_directeur', 'csi_affecte'];
      case 'rapport_annuel_1':
        return ['activation', 'choix_directeur', 'validation_directeur', 'csi_affecte', 'rapport1'];
      case 'rapport_annuel_1_valide':
        return ['activation', 'choix_directeur', 'validation_directeur', 'csi_affecte', 'rapport1'];
      case 'rapport_annuel_2':
        return ['activation', 'choix_directeur', 'validation_directeur', 'csi_affecte', 'rapport1', 'rapport2'];
      case 'rapport_annuel_2_valide':
        return ['activation', 'choix_directeur', 'validation_directeur', 'csi_affecte', 'rapport1', 'rapport2'];
      case 'rapport_annuel_3':
        return ['activation', 'choix_directeur', 'validation_directeur', 'csi_affecte', 'rapport1', 'rapport2', 'rapport3'];
      case 'rapport_annuel_3_valide':
        return ['activation', 'choix_directeur', 'validation_directeur', 'csi_affecte', 'rapport1', 'rapport2', 'rapport3'];
      case 'manuscrit_depose':
        return ['activation', 'choix_directeur', 'validation_directeur', 'csi_affecte', 'rapport1', 'rapport2', 'rapport3', 'manuscrit'];
      case 'quitus_directeur':
        return ['activation', 'choix_directeur', 'validation_directeur', 'csi_affecte', 'rapport1', 'rapport2', 'rapport3', 'manuscrit', 'quitus_dir'];
      case 'quitus_csi':
        return ['activation', 'choix_directeur', 'validation_directeur', 'csi_affecte', 'rapport1', 'rapport2', 'rapport3', 'manuscrit', 'quitus_dir', 'quitus_csi'];
      case 'validation_admin':
        return ['activation', 'choix_directeur', 'validation_directeur', 'csi_affecte', 'rapport1', 'rapport2', 'rapport3', 'manuscrit', 'quitus_dir', 'quitus_csi'];
      case 'rapporteurs_affectes':
        return ['activation', 'choix_directeur', 'validation_directeur', 'csi_affecte', 'rapport1', 'rapport2', 'rapport3', 'manuscrit', 'quitus_dir', 'quitus_csi', 'rapporteurs'];
      case 'evaluation_rapporteurs':
        return ['activation', 'choix_directeur', 'validation_directeur', 'csi_affecte', 'rapport1', 'rapport2', 'rapport3', 'manuscrit', 'quitus_dir', 'quitus_csi', 'rapporteurs'];
      case 'soutenance_programmee':
        return ['activation', 'choix_directeur', 'validation_directeur', 'csi_affecte', 'rapport1', 'rapport2', 'rapport3', 'manuscrit', 'quitus_dir', 'quitus_csi', 'rapporteurs', 'soutenance'];
      case 'soutenance_realisee':
        return ['activation', 'choix_directeur', 'validation_directeur', 'csi_affecte', 'rapport1', 'rapport2', 'rapport3', 'manuscrit', 'quitus_dir', 'quitus_csi', 'rapporteurs', 'soutenance'];
      default:
        return ['activation'];
    }
  }

  String _getCurrentKey(String etape) {
    switch (etape) {
      case 'enregistree':
        return 'choix_directeur';
      case 'directeur_choisi':
        return 'validation_directeur';
      case 'directeur_valide':
        return 'csi_affecte';
      case 'csi_affecte':
        return 'rapport1';
      case 'rapport_annuel_1':
        return 'rapport1';
      case 'rapport_annuel_1_valide':
        return 'rapport2';
      case 'rapport_annuel_2':
        return 'rapport2';
      case 'rapport_annuel_2_valide':
        return 'rapport3';
      case 'rapport_annuel_3':
        return 'rapport3';
      case 'rapport_annuel_3_valide':
        return 'manuscrit';
      case 'manuscrit_depose':
        return 'quitus_dir';
      case 'quitus_directeur':
        return 'quitus_csi';
      case 'quitus_csi':
        return 'quitus_csi';
      case 'validation_admin':
        return 'rapporteurs';
      case 'rapporteurs_affectes':
        return 'soutenance';
      case 'evaluation_rapporteurs':
        return 'soutenance';
      case 'soutenance_programmee':
        return 'soutenance';
      case 'soutenance_realisee':
        return 'soutenance';
      default:
        return 'choix_directeur';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM NAV
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBottomNav(BuildContext context, int index) {
    return NavigationBar(
      selectedIndex: index,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE8F5E9),
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go(AppRoutes.dashboard);
            break;
          case 1:
            context.go(AppRoutes.these);
            break;
          case 2:
            context.go(AppRoutes.notifications);
            break;
          case 3:
            context.go(AppRoutes.opportunites);
            break;
          case 4:
            context.go(AppRoutes.profil);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppTheme.primaryColor),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description, color: AppTheme.primaryColor),
          label: 'Thèse',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications, color: AppTheme.primaryColor),
          label: 'Alertes',
        ),
        NavigationDestination(
          icon: Icon(Icons.lightbulb_outlined),
          selectedIcon: Icon(Icons.lightbulb, color: AppTheme.primaryColor),
          label: 'Opportunités',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor),
          label: 'Profil',
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOADING CARD
// ═══════════════════════════════════════════════════════════════════════════

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
