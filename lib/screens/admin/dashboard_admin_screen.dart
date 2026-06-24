import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';

class DashboardAdminScreen extends ConsumerStatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  ConsumerState<DashboardAdminScreen> createState() =>
      _DashboardAdminScreenState();
}

class _DashboardAdminScreenState
    extends ConsumerState<DashboardAdminScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _VueAccueil(),
          _VueSuivi(),
          _VueAnalytique(),
          _VueProfil(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDEF0DE),
        elevation: 8,
        onDestinationSelected: (i) =>
            setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard,
                color: AppTheme.primaryColor),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            selectedIcon: Icon(Icons.track_changes,
                color: AppTheme.primaryColor),
            label: 'Suivi',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart,
                color: AppTheme.primaryColor),
            label: 'Analytique',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon:
            Icon(Icons.person, color: AppTheme.primaryColor),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VUE 1 — ACCUEIL
// ═══════════════════════════════════════════════════════════════════════════
class _VueAccueil extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return CustomScrollView(
      slivers: [
        // AppBar personnalisée
        SliverAppBar(
          pinned: true,
          expandedHeight: 130,
          backgroundColor: AppTheme.primaryColor,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A5C2A),
                    Color(0xFF2E7D42),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding:
              const EdgeInsets.fromLTRB(16, 48, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text('Bienvenue,',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12)),
                          const Text('Administration UJKZ',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight:
                                  FontWeight.w600)),
                          Text(
                            _dateAujourdhui(),
                            style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _IconBtn(
                            icon: Icons.notifications_outlined,
                            badge: true,
                            onTap: () => context.push(
                                AppRoutes.notificationsAdmin),
                          ),
                          const SizedBox(width: 6),
                          _IconBtn(
                            icon: Icons.send_outlined,
                            onTap: () => context.push(
                                AppRoutes.envoyerNotification),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(14),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Statistiques réelles
              statsAsync.when(
                data: (stats) => _SectionStats(stats: stats),
                loading: () => const _LoadingCard(),
                error: (e, _) =>
                    _ErrorCard(message: e.toString()),
              ),
              const SizedBox(height: 16),
              // Actions rapides
              const _SectionActionsRapides(),
              const SizedBox(height: 16),
              // Centre de suivi rapide
              const _SectionSuiviRapide(),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  String _dateAujourdhui() {
    final now = DateTime.now();
    final jours = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi',
      'Vendredi', 'Samedi', 'Dimanche'
    ];
    final mois = [
      'jan.', 'fév.', 'mar.', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sep.', 'oct.', 'nov.', 'déc.'
    ];
    return '${jours[now.weekday - 1]} ${now.day} ${mois[now.month - 1]} ${now.year}';
  }
}

// ── Section Statistiques ─────────────────────────────────────────────────
class _SectionStats extends StatelessWidget {
  final Map<String, int> stats;
  const _SectionStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('VUE D\'ENSEMBLE'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _StatCard(
              label: 'Doctorants',
              value: stats['doctorants'] ?? 0,
              icon: Icons.school_rounded,
              color: AppTheme.primaryColor,
              bgColor: const Color(0xFFE8F5E9),
              onTap: () => context.push(AppRoutes.gestionDoctorants),
            ),
            _StatCard(
              label: 'Directeurs',
              value: stats['directeurs'] ?? 0,
              icon: Icons.person_pin_rounded,
              color: const Color(0xFF0D47A1),
              bgColor: const Color(0xFFE3F2FD),
              onTap: () =>
                  context.push(AppRoutes.gestionDirecteurs),
            ),
            _StatCard(
              label: 'Rapporteurs',
              value: stats['rapporteurs'] ?? 0,
              icon: Icons.rate_review_rounded,
              color: const Color(0xFF6A1B9A),
              bgColor: const Color(0xFFF3E5F5),
              onTap: () =>
                  context.push(AppRoutes.gestionRapporteurs),
            ),
            _StatCard(
              label: 'Membres CSI',
              value: stats['csi'] ?? 0,
              icon: Icons.groups_rounded,
              color: const Color(0xFF00695C),
              bgColor: const Color(0xFFE0F2F1),
              onTap: () => context.push(AppRoutes.gestionCSI),
            ),
            _StatCard(
              label: 'Thèses',
              value: stats['theses'] ?? 0,
              icon: Icons.menu_book_rounded,
              color: const Color(0xFFE65100),
              bgColor: const Color(0xFFFFF3E0),
              onTap: () =>
                  context.push(AppRoutes.gestionTheses),
            ),
            _StatCard(
              label: 'Manuscrits',
              value: stats['manuscrits'] ?? 0,
              icon: Icons.upload_file_rounded,
              color: const Color(0xFF37474F),
              bgColor: const Color(0xFFECEFF1),
              onTap: () =>
                  context.push(AppRoutes.gestionManuscrits),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Stats comptes actifs/inactifs
        _StatsBarreInfo(stats: stats),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: color.withOpacity(0.5)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textGray,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsBarreInfo extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsBarreInfo({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = (stats['doctorants'] ?? 0) +
        (stats['directeurs'] ?? 0) +
        (stats['rapporteurs'] ?? 0) +
        (stats['csi'] ?? 0);

    return Container(
      padding: const EdgeInsets.all(14),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniInfo(
            label: 'Total utilisateurs',
            value: total.toString(),
            color: AppTheme.primaryColor,
          ),
          Container(
              width: 1, height: 30, color: const Color(0xFFEEEEEE)),
          _MiniInfo(
            label: 'Soutenances',
            value: (stats['soutenances'] ?? 0).toString(),
            color: const Color(0xFFC62828),
          ),
          Container(
              width: 1, height: 30, color: const Color(0xFFEEEEEE)),
          _MiniInfo(
            label: 'Manuscrits',
            value: (stats['manuscrits'] ?? 0).toString(),
            color: const Color(0xFF37474F),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniInfo(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 9, color: AppTheme.textGray)),
      ],
    );
  }
}

// ── Section Actions Rapides ──────────────────────────────────────────────
class _SectionActionsRapides extends StatelessWidget {
  const _SectionActionsRapides();

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'label': 'Créer\nDirecteur',
        'icon': Icons.person_add_rounded,
        'color': const Color(0xFF0D47A1),
        'bg': const Color(0xFFE3F2FD),
        'route': AppRoutes.ajouterDirecteur,
      },
      {
        'label': 'Créer\nRapporteur',
        'icon': Icons.rate_review_rounded,
        'color': const Color(0xFF6A1B9A),
        'bg': const Color(0xFFF3E5F5),
        'route': AppRoutes.ajouterRapporteur,
      },
      {
        'label': 'Créer\nCSI',
        'icon': Icons.group_add_rounded,
        'color': const Color(0xFF00695C),
        'bg': const Color(0xFFE0F2F1),
        'route': AppRoutes.ajouterCSI,
      },
      {
        'label': 'Envoyer\nNotif.',
        'icon': Icons.campaign_rounded,
        'color': const Color(0xFFE65100),
        'bg': const Color(0xFFFFF3E0),
        'route': AppRoutes.envoyerNotification,
      },
      {
        'label': 'Planifier\nSoutenance',
        'icon': Icons.event_available_rounded,
        'color': const Color(0xFFC62828),
        'bg': const Color(0xFFFFEBEE),
        'route': AppRoutes.gestionSoutenances,
      },
      {
        'label': 'Attribuer\nRapporteurs',
        'icon': Icons.auto_awesome_rounded,
        'color': AppTheme.primaryColor,
        'bg': const Color(0xFFE8F5E9),
        'route': AppRoutes.gestionTheses,
      },
      {
        'label': 'Manuscrits\nEn attente',
        'icon': Icons.pending_actions_rounded,
        'color': const Color(0xFF37474F),
        'bg': const Color(0xFFECEFF1),
        'route': AppRoutes.gestionManuscrits,
      },
      {
        'label': 'Doctorants\nListe',
        'icon': Icons.school_rounded,
        'color': AppTheme.primaryColor,
        'bg': const Color(0xFFE8F5E9),
        'route': AppRoutes.gestionDoctorants,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('ACTIONS RAPIDES'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: actions.map((a) {
            return GestureDetector(
              onTap: () =>
                  context.push(a['route'] as String),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (a['color'] as Color)
                          .withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: a['bg'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(a['icon'] as IconData,
                          color: a['color'] as Color, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a['label'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 9,
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w500,
                          height: 1.3),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Section Suivi Rapide ─────────────────────────────────────────────────
class _SectionSuiviRapide extends ConsumerWidget {
  const _SectionSuiviRapide();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manuscritsAsync = ref.watch(manuscritsEnAttenteProvider);
    final notifsAsync = ref.watch(notificationsAdminProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('CENTRE DE SUIVI'),
        const SizedBox(height: 10),
        // Manuscrits en attente
        manuscritsAsync.when(
          data: (manuscrits) => manuscrits.isEmpty
              ? const SizedBox()
              : _AlerteCard(
            titre: 'Manuscrits en attente',
            nombre: manuscrits.length,
            sousTitre:
            'nécessitent une validation',
            icon: Icons.upload_file_rounded,
            color: const Color(0xFFE65100),
            bgColor: const Color(0xFFFFF3E0),
            onTap: () => context.push(
                AppRoutes.gestionManuscrits),
          ),
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
        const SizedBox(height: 8),
        // Notifications récentes
        notifsAsync.when(
          data: (notifs) {
            final nonLues =
            notifs.where((n) => !n.lu).toList();
            return nonLues.isEmpty
                ? const SizedBox()
                : _AlerteCard(
              titre: 'Notifications non lues',
              nombre: nonLues.length,
              sousTitre: 'en attente de lecture',
              icon: Icons.notifications_active_rounded,
              color: AppTheme.primaryColor,
              bgColor: const Color(0xFFE8F5E9),
              onTap: () => context.push(
                  AppRoutes.notificationsAdmin),
            );
          },
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
        const SizedBox(height: 8),
        // Accès rapide gestion thèses
        _CarteAccesModule(
          titre: 'Gestion des Thèses',
          description:
          'Suivre l\'avancement, changer les statuts et attribuer des rapporteurs',
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF1565C0),
          onTap: () => context.push(AppRoutes.gestionTheses),
        ),
        const SizedBox(height: 8),
        _CarteAccesModule(
          titre: 'Soutenances',
          description:
          'Planifier et gérer les soutenances de thèse',
          icon: Icons.event_available_rounded,
          color: const Color(0xFFC62828),
          onTap: () =>
              context.push(AppRoutes.gestionSoutenances),
        ),
      ],
    );
  }
}

class _AlerteCard extends StatelessWidget {
  final String titre;
  final int nombre;
  final String sousTitre;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _AlerteCard({
    required this.titre,
    required this.nombre,
    required this.sousTitre,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
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
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  Text('$nombre $sousTitre',
                      style: TextStyle(
                          fontSize: 11, color: color)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                nombre.toString(),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right,
                color: color.withOpacity(0.6), size: 20),
          ],
        ),
      ),
    );
  }
}

class _CarteAccesModule extends StatelessWidget {
  final String titre;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CarteAccesModule({
    required this.titre,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textGray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VUE 2 — SUIVI
// ═══════════════════════════════════════════════════════════════════════════
class _VueSuivi extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manuscritsAsync = ref.watch(manuscritsEnAttenteProvider);
    final notifsAsync = ref.watch(notificationsAdminProvider);
    final soutenancesAsync = ref.watch(soutenancesAdminProvider);

    return CustomScrollView(
      slivers: [
        _buildAppBar('Centre de Suivi', context),
        SliverPadding(
          padding: const EdgeInsets.all(14),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Manuscrits en attente
              _TitreSection('MANUSCRITS EN ATTENTE'),
              const SizedBox(height: 8),
              manuscritsAsync.when(
                data: (manuscrits) => manuscrits.isEmpty
                    ? _EmptyState(
                    message: 'Aucun manuscrit en attente',
                    icon: Icons.upload_file_outlined)
                    : Column(
                  children: manuscrits.map((m) {
                    return _ManuscritSuiviCard(
                        manuscrit: m, ref: ref);
                  }).toList(),
                ),
                loading: () => const _LoadingCard(),
                error: (e, _) =>
                    _ErrorCard(message: e.toString()),
              ),
              const SizedBox(height: 16),
              // Soutenances
              _TitreSection('SOUTENANCES PROGRAMMÉES'),
              const SizedBox(height: 8),
              soutenancesAsync.when(
                data: (soutenances) => soutenances.isEmpty
                    ? _EmptyState(
                    message: 'Aucune soutenance programmée',
                    icon: Icons.event_outlined)
                    : Column(
                  children: soutenances.take(5).map((s) {
                    return Container(
                      margin:
                      const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.04),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(
                                  0xFFFFEBEE),
                              borderRadius:
                              BorderRadius.circular(
                                  12),
                            ),
                            child: const Icon(Icons.event,
                                color: Color(0xFFC62828),
                                size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.dateSoutenance,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                      FontWeight.w600),
                                ),
                                Text(
                                  '${s.heure} — ${s.lieu}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color:
                                      AppTheme.textGray),
                                ),
                                Text(
                                  'Président: ${s.presidentJury}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color:
                                      AppTheme.textGray),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                loading: () => const _LoadingCard(),
                error: (e, _) =>
                    _ErrorCard(message: e.toString()),
              ),
              const SizedBox(height: 16),
              // Notifications récentes
              _TitreSection('NOTIFICATIONS RÉCENTES'),
              const SizedBox(height: 8),
              notifsAsync.when(
                data: (notifs) => notifs.isEmpty
                    ? _EmptyState(
                    message: 'Aucune notification',
                    icon: Icons.notifications_none)
                    : Column(
                  children: notifs.take(5).map((n) {
                    return Container(
                      margin:
                      const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border(
                          left: BorderSide(
                            color: n.lu
                                ? Colors.transparent
                                : AppTheme.primaryColor,
                            width: 3,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.03),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(
                                  0xFFE8F5E9),
                              borderRadius:
                              BorderRadius.circular(
                                  10),
                            ),
                            child: const Icon(
                                Icons.notifications,
                                color:
                                AppTheme.primaryColor,
                                size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(n.titre,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: n.lu
                                            ? FontWeight
                                            .normal
                                            : FontWeight
                                            .w600)),
                                Text(n.message,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme
                                            .textGray),
                                    maxLines: 1,
                                    overflow: TextOverflow
                                        .ellipsis),
                              ],
                            ),
                          ),
                          if (!n.lu)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                loading: () => const _LoadingCard(),
                error: (e, _) =>
                    _ErrorCard(message: e.toString()),
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ManuscritSuiviCard extends StatelessWidget {
  final Map<String, dynamic> manuscrit;
  final WidgetRef ref;
  const _ManuscritSuiviCard(
      {required this.manuscrit, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFFFCC80), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.upload_file,
                    color: Color(0xFFE65100), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manuscrit['titre'] ?? 'Sans titre',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Déposé le ${manuscrit['date_depot'] ?? '–'}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textGray),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('En attente',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.orangeColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await AdminService()
                        .rejeterManuscrit(manuscrit['id']);
                    ref.invalidate(manuscritsEnAttenteProvider);
                    ref.invalidate(adminStatsProvider);
                  },
                  icon: const Icon(Icons.close,
                      size: 14, color: Colors.red),
                  label: const Text('Rejeter',
                      style: TextStyle(
                          color: Colors.red, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await AdminService()
                        .validerManuscrit(manuscrit['id']);
                    ref.invalidate(manuscritsEnAttenteProvider);
                    ref.invalidate(adminStatsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Manuscrit validé !'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Valider',
                      style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VUE 3 — ANALYTIQUE
// ═══════════════════════════════════════════════════════════════════════════
class _VueAnalytique extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final thesesAsync = ref.watch(thesesAdminProvider);

    return CustomScrollView(
      slivers: [
        _buildAppBar('Analytique', context),
        SliverPadding(
          padding: const EdgeInsets.all(14),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Répartition utilisateurs
              statsAsync.when(
                data: (stats) => _GrapheRepartition(stats: stats),
                loading: () => const _LoadingCard(),
                error: (e, _) =>
                    _ErrorCard(message: e.toString()),
              ),
              const SizedBox(height: 16),
              // Statuts des thèses
              thesesAsync.when(
                data: (theses) =>
                    _GrapheThesesStatuts(theses: theses
                        .map((t) =>
                    {'etat': t.etat, 'titre': t.titre})
                        .toList()),
                loading: () => const _LoadingCard(),
                error: (e, _) =>
                    _ErrorCard(message: e.toString()),
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }
}

class _GrapheRepartition extends StatelessWidget {
  final Map<String, int> stats;
  const _GrapheRepartition({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = (stats['doctorants'] ?? 0) +
        (stats['directeurs'] ?? 0) +
        (stats['rapporteurs'] ?? 0) +
        (stats['csi'] ?? 0);

    if (total == 0) {
      return _EmptyState(
          message: 'Aucune donnée disponible',
          icon: Icons.bar_chart_outlined);
    }

    final barres = [
      {
        'label': 'Doctorants',
        'value': stats['doctorants'] ?? 0,
        'color': AppTheme.primaryColor,
      },
      {
        'label': 'Directeurs',
        'value': stats['directeurs'] ?? 0,
        'color': const Color(0xFF0D47A1),
      },
      {
        'label': 'Rapporteurs',
        'value': stats['rapporteurs'] ?? 0,
        'color': const Color(0xFF6A1B9A),
      },
      {
        'label': 'CSI',
        'value': stats['csi'] ?? 0,
        'color': const Color(0xFF00695C),
      },
    ];

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
          const _TitreSection('RÉPARTITION DES UTILISATEURS'),
          const SizedBox(height: 16),
          ...barres.map((b) {
            final value = b['value'] as int;
            final ratio = total > 0 ? value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(b['label'] as String,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      Text(value.toString(),
                          style: TextStyle(
                              fontSize: 12,
                              color: b['color'] as Color,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(
                          b['color'] as Color),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(ratio * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textGray),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total utilisateurs',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textGray)),
              Text(total.toString(),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrapheThesesStatuts extends StatelessWidget {
  final List<Map<String, dynamic>> theses;
  const _GrapheThesesStatuts({required this.theses});

  @override
  Widget build(BuildContext context) {
    if (theses.isEmpty) {
      return _EmptyState(
          message: 'Aucune thèse enregistrée',
          icon: Icons.description_outlined);
    }

    final Map<String, int> parStatut = {};
    for (final t in theses) {
      final etat = t['etat'] as String? ?? 'inconnu';
      parStatut[etat] = (parStatut[etat] ?? 0) + 1;
    }

    final couleurs = {
      'enregistree': AppTheme.primaryColor,
      'en cours': const Color(0xFF0D47A1),
      'en instruction': const Color(0xFF6A1B9A),
      'soutenue': const Color(0xFF00695C),
      'abandonnee': const Color(0xFFC62828),
    };

    final libelles = {
      'enregistree': 'Enregistrée',
      'en cours': 'En cours',
      'en instruction': 'En instruction',
      'soutenue': 'Soutenue',
      'abandonnee': 'Abandonnée',
    };

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
          const _TitreSection('THÈSES PAR STATUT'),
          const SizedBox(height: 16),
          ...parStatut.entries.map((entry) {
            final color = couleurs[entry.key] ??
                AppTheme.primaryColor;
            final libelle =
                libelles[entry.key] ?? entry.key;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: color.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(libelle,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w500)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Text(
                      entry.value.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total thèses',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGray)),
              Text(theses.length.toString(),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor)),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VUE 4 — PROFIL
// ═══════════════════════════════════════════════════════════════════════════
class _VueProfil extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final statsAsync = ref.watch(adminStatsProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 3),
                    ),
                    child: const Center(
                      child: Text('AD',
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Administrateur',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600)),
                  Text(user?.email ?? '',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('UJKZ — EDS · EDLESHC · EDST',
                        style: TextStyle(
                            color: Colors.white, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(14),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Stats globales
              statsAsync.when(
                data: (stats) => Container(
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
                      const _TitreSection(
                          'STATISTIQUES GLOBALES'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ProfilStat(
                              (stats['doctorants'] ?? 0)
                                  .toString(),
                              'Doctorants'),
                          const SizedBox(width: 8),
                          _ProfilStat(
                              (stats['theses'] ?? 0)
                                  .toString(),
                              'Thèses'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _ProfilStat(
                              (stats['rapporteurs'] ?? 0)
                                  .toString(),
                              'Rapporteurs'),
                          const SizedBox(width: 8),
                          _ProfilStat(
                              (stats['soutenances'] ?? 0)
                                  .toString(),
                              'Soutenances'),
                        ],
                      ),
                    ],
                  ),
                ),
                loading: () => const _LoadingCard(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 12),
              // Menu profil
              Container(
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
                    _MenuProfilItem(
                      icon: Icons.people_outline,
                      label: 'Gestion Doctorants',
                      onTap: () => context
                          .push(AppRoutes.gestionDoctorants),
                    ),
                    const Divider(height: 1, indent: 56),
                    _MenuProfilItem(
                      icon: Icons.description_outlined,
                      label: 'Gestion Thèses',
                      onTap: () =>
                          context.push(AppRoutes.gestionTheses),
                    ),
                    const Divider(height: 1, indent: 56),
                    _MenuProfilItem(
                      icon: Icons.notifications_outlined,
                      label: 'Envoyer une notification',
                      onTap: () => context
                          .push(AppRoutes.envoyerNotification),
                    ),
                    const Divider(height: 1, indent: 56),
                    _MenuProfilItem(
                      icon: Icons.settings_outlined,
                      label: 'Paramètres',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Déconnexion
              GestureDetector(
                onTap: () async {
                  await AdminService()
                      .getStatistiques(); // flush cache
                  await Supabase.instance.client.auth
                      .signOut();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFFFCDD2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.04),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Se déconnecter',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }
}

Widget _ProfilStat(String value, String label) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textGray)),
        ],
      ),
    ),
  );
}

class _MenuProfilItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuProfilItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: AppTheme.primaryColor, size: 18),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right,
          color: Colors.grey, size: 18),
      onTap: onTap,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS COMMUNS
// ═══════════════════════════════════════════════════════════════════════════

SliverAppBar _buildAppBar(String titre, BuildContext context) {
  return SliverAppBar(
    pinned: true,
    backgroundColor: AppTheme.primaryColor,
    automaticallyImplyLeading: false,
    title: Text(titre,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600)),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh, color: Colors.white70),
        onPressed: () {},
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF4A7A4A),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _TitreSection extends StatelessWidget {
  final String text;
  const _TitreSection(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF4A7A4A),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool badge;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Center(
                child: Icon(icon, color: Colors.white, size: 20)),
            if (badge)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.orangeColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Erreur: $message',
              style: const TextStyle(
                  fontSize: 12, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyState(
      {required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 40,
              color: AppTheme.primaryColor.withOpacity(0.4)),
          const SizedBox(height: 10),
          Text(message,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textGray),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}