import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/admin_provider.dart';

class DashboardAdminScreen extends ConsumerWidget {
  const DashboardAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final notifsAsync = ref.watch(notificationsAdminProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats
                statsAsync.when(
                  data: (stats) => _buildStatsSection(context, stats),
                  loading: () => const Center(
                      child: CircularProgressIndicator()),
                  error: (e, _) => Text('Erreur: $e'),
                ),
                const SizedBox(height: 12),
                // Accès rapides
                _buildAccesRapides(context),
                const SizedBox(height: 12),
                // Manuscrits en attente
                _buildManuscritsSection(context, ref),
                const SizedBox(height: 12),
                // Notifications récentes
                notifsAsync.when(
                  data: (notifs) =>
                      _buildNotificationsSection(context, notifs),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
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

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppTheme.primaryColor,
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Administration',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  const Text('DoctoApp UJKZ',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500)),
                  const Text(
                      'EDS · EDLESHC · EDST',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 11)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        context.push(AppRoutes.notificationsAdmin),
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 24),
                        Positioned(
                          right: 0,
                          top: 0,
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
                  IconButton(
                    onPressed: () =>
                        context.push(AppRoutes.profilAdmin),
                    icon: const Icon(Icons.account_circle_outlined,
                        color: Colors.white, size: 24),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(
      BuildContext context, Map<String, int> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('VUE D\'ENSEMBLE',
            style: TextStyle(
                fontSize: 11,
                color: Color(0xFF4A7A4A),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: [
            _buildStatCard('Doctorants',
                stats['doctorants'].toString(),
                Icons.school_outlined, AppTheme.primaryColor,
                    () => context.push(AppRoutes.gestionDoctorants)),
            _buildStatCard('Directeurs',
                stats['directeurs'].toString(),
                Icons.person_outlined, const Color(0xFF0D47A1),
                    () => context.push(AppRoutes.gestionDirecteurs)),
            _buildStatCard('Rapporteurs',
                stats['rapporteurs'].toString(),
                Icons.rate_review_outlined, const Color(0xFF6A1B9A),
                    () => context.push(AppRoutes.gestionRapporteurs)),
            _buildStatCard('Membres CSI',
                stats['csi'].toString(),
                Icons.people_outlined, const Color(0xFF00695C),
                    () => context.push(AppRoutes.gestionCSI)),
            _buildStatCard('Thèses',
                stats['theses'].toString(),
                Icons.description_outlined, const Color(0xFFE65100),
                    () => context.push(AppRoutes.gestionTheses)),
            _buildStatCard('Soutenances',
                stats['soutenances'].toString(),
                Icons.event_outlined, const Color(0xFFC62828),
                    () => context.push(AppRoutes.gestionSoutenances)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFDDE8DD), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textGray)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccesRapides(BuildContext context) {
    final modules = [
      {
        'label': 'Doctorants',
        'icon': Icons.school_outlined,
        'color': AppTheme.primaryColor,
        'route': AppRoutes.gestionDoctorants,
      },
      {
        'label': 'Directeurs',
        'icon': Icons.person_outlined,
        'color': const Color(0xFF0D47A1),
        'route': AppRoutes.gestionDirecteurs,
      },
      {
        'label': 'Rapporteurs',
        'icon': Icons.rate_review_outlined,
        'color': const Color(0xFF6A1B9A),
        'route': AppRoutes.gestionRapporteurs,
      },
      {
        'label': 'CSI',
        'icon': Icons.people_outlined,
        'color': const Color(0xFF00695C),
        'route': AppRoutes.gestionCSI,
      },
      {
        'label': 'Thèses',
        'icon': Icons.description_outlined,
        'color': const Color(0xFFE65100),
        'route': AppRoutes.gestionTheses,
      },
      {
        'label': 'Soutenances',
        'icon': Icons.event_outlined,
        'color': const Color(0xFFC62828),
        'route': AppRoutes.gestionSoutenances,
      },
      {
        'label': 'Manuscrits',
        'icon': Icons.upload_file_outlined,
        'color': const Color(0xFF37474F),
        'route': AppRoutes.gestionManuscrits,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACCÈS RAPIDES',
            style: TextStyle(
                fontSize: 11,
                color: Color(0xFF4A7A4A),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final m = modules[index];
              return GestureDetector(
                onTap: () => context.push(m['route'] as String),
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFDDE8DD), width: 0.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(m['icon'] as IconData,
                          color: m['color'] as Color, size: 24),
                      const SizedBox(height: 4),
                      Text(m['label'] as String,
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppTheme.textGray),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildManuscritsSection(BuildContext context, WidgetRef ref) {
    final manuscritsAsync = ref.watch(manuscritsEnAttenteProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MANUSCRITS EN ATTENTE',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4A7A4A),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5)),
              TextButton(
                onPressed: () =>
                    context.push(AppRoutes.gestionManuscrits),
                child: const Text('Voir tout',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryColor)),
              ),
            ],
          ),
          manuscritsAsync.when(
            data: (manuscrits) => manuscrits.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Aucun manuscrit en attente',
                  style: TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 12)),
            )
                : Column(
              children: manuscrits.take(3).map((m) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.upload_file,
                        color: AppTheme.orangeColor, size: 18),
                  ),
                  title: Text(
                      m['titre'] ?? 'Manuscrit',
                      style: const TextStyle(fontSize: 12)),
                  subtitle: const Text('En attente de validation',
                      style: TextStyle(fontSize: 10)),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppTheme.textGray),
                );
              }).toList(),
            ),
            loading: () =>
            const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(
      BuildContext context, List notifications) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('NOTIFICATIONS RÉCENTES',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4A7A4A),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5)),
              TextButton(
                onPressed: () =>
                    context.push(AppRoutes.notificationsAdmin),
                child: const Text('Voir tout',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryColor)),
              ),
            ],
          ),
          if (notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Aucune notification',
                  style: TextStyle(
                      color: AppTheme.textGray, fontSize: 12)),
            )
          else
            ...notifications.take(3).map((n) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications,
                  color: AppTheme.primaryColor, size: 20),
              title: Text(n.titre,
                  style: const TextStyle(fontSize: 12)),
              subtitle: Text(n.message,
                  style: const TextStyle(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            )),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int index) {
    return NavigationBar(
      selectedIndex: index,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE8F5E9),
      onDestinationSelected: (i) {
        switch (i) {
          case 0: context.go(AppRoutes.dashboardAdmin); break;
          case 1: context.go(AppRoutes.gestionDoctorants); break;
          case 2: context.go(AppRoutes.gestionTheses); break;
          case 3: context.go(AppRoutes.notificationsAdmin); break;
          case 4: context.go(AppRoutes.profilAdmin); break;
        }
      },
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryColor),
            label: 'Tableau'),
        NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school, color: AppTheme.primaryColor),
            label: 'Doctorants'),
        NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description, color: AppTheme.primaryColor),
            label: 'Thèses'),
        NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications, color: AppTheme.primaryColor),
            label: 'Alertes'),
        NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor),
            label: 'Profil'),
      ],
    );
  }
}