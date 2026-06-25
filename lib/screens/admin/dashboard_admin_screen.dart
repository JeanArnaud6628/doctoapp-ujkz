import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import 'vues/vue_generale.dart';
import 'vues/vue_cycle_doctoral.dart';
import 'vues/vue_gestion.dart';
import 'vues/vue_alertes_historique.dart';

class DashboardAdminScreen extends ConsumerStatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  ConsumerState<DashboardAdminScreen> createState() =>
      _DashboardAdminScreenState();
}

class _DashboardAdminScreenState
    extends ConsumerState<DashboardAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);
    final alertesAsync = ref.watch(alertesProvider);

    final int nbAlertes = alertesAsync.when(
      data: (a) => a.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: Column(
        children: [
          // Header principal
          _buildHeader(context, statsAsync, nbAlertes),
          // Corps avec onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                VueGenerale(),
                VueCycleDoctoral(),
                VueGestion(),
                VueAlertesHistorique(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(nbAlertes),
    );
  }

  Widget _buildHeader(BuildContext context,
      AsyncValue<Map<String, int>> statsAsync, int nbAlertes) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A5C2A), Color(0xFF2E7D42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Barre titre
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Administration',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11)),
                        Text('DoctoApp UJKZ',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  // Notifications
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white),
                        onPressed: () => context
                            .push(AppRoutes.notificationsAdmin),
                      ),
                      if (nbAlertes > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              nbAlertes > 9
                                  ? '9+'
                                  : nbAlertes.toString(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_outlined,
                        color: Colors.white),
                    onPressed: () => context
                        .push(AppRoutes.envoyerNotification),
                  ),
                ],
              ),
            ),
            // Résumé statistiques rapides
            statsAsync.when(
              data: (stats) => _buildStatsRapides(stats),
              loading: () => const SizedBox(height: 60),
              error: (_, __) => const SizedBox(height: 60),
            ),
            // TabBar
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
              const TextStyle(fontSize: 11),
              isScrollable: false,
              tabs: const [
                Tab(text: 'Général'),
                Tab(text: 'Cycle'),
                Tab(text: 'Gestion'),
                Tab(text: 'Alertes'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRapides(Map<String, int> stats) {
    final items = [
      {'label': 'Doctorants', 'v': stats['doctorants'] ?? 0, 'icon': Icons.school},
      {'label': 'Thèses actives', 'v': stats['theses_actives'] ?? 0, 'icon': Icons.menu_book},
      {'label': 'Manuscrits att.', 'v': stats['manuscrits_attente'] ?? 0, 'icon': Icons.upload_file},
      {'label': 'Alertes', 'v': (stats['quitus_dir_manquants'] ?? 0) + (stats['avis_csi_manquants'] ?? 0), 'icon': Icons.warning_amber},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    (item['v'] as int).toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['label'] as String,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 9),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomNav(int nbAlertes) {
    return NavigationBar(
      selectedIndex: _bottomIndex,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFDEF0DE),
      elevation: 8,
      onDestinationSelected: (i) {
        setState(() => _bottomIndex = i);
        switch (i) {
          case 0:
            _tabController.animateTo(0);
            break;
          case 1:
            context.push(AppRoutes.gestionDoctorants);
            break;
          case 2:
            context.push(AppRoutes.gestionTheses);
            break;
          case 3:
            context.push(AppRoutes.profilAdmin);
            break;
        }
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon:
          Icon(Icons.dashboard, color: AppTheme.primaryColor),
          label: 'Tableau',
        ),
        const NavigationDestination(
          icon: Icon(Icons.school_outlined),
          selectedIcon:
          Icon(Icons.school, color: AppTheme.primaryColor),
          label: 'Doctorants',
        ),
        const NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon:
          Icon(Icons.menu_book, color: AppTheme.primaryColor),
          label: 'Thèses',
        ),
        NavigationDestination(
          icon: Stack(
            children: [
              const Icon(Icons.person_outline),
              if (nbAlertes > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Profil',
        ),
      ],
    );
  }
}