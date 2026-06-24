import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';

class ProfilAdminScreen extends ConsumerWidget {
  const ProfilAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.primaryColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 64,
                      height: 64,
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
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Administrateur',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                    Text(user?.email ?? '',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('DoctoApp UJKZ',
                          style: TextStyle(
                              color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats
                statsAsync.when(
                  data: (stats) => Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFDDE8DD),
                          width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('STATISTIQUES GLOBALES',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF4A7A4A),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildMiniStat(
                                stats['doctorants'].toString(),
                                'Doctorants'),
                            const SizedBox(width: 8),
                            _buildMiniStat(
                                stats['theses'].toString(),
                                'Thèses'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildMiniStat(
                                stats['rapporteurs'].toString(),
                                'Rapporteurs'),
                            const SizedBox(width: 8),
                            _buildMiniStat(
                                stats['soutenances'].toString(),
                                'Soutenances'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 10),
                // Actions rapides
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFDDE8DD), width: 0.5),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                          Icons.settings_outlined,
                          'Paramètres',
                          'Configuration du système',
                              () {}),
                      const Divider(height: 1),
                      _buildMenuItem(
                          Icons.help_outline,
                          'Aide',
                          'Documentation',
                              () {}),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(authProvider.notifier)
                        .deconnecter();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(
                        color: Color(0xFFFFCDD2)),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter',
                      style:
                      TextStyle(fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 4,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8F5E9),
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go(AppRoutes.dashboardAdmin); break;
            case 1: context.go(AppRoutes.gestionDoctorants); break;
            case 2: context.go(AppRoutes.gestionTheses); break;
            case 3: context.go(AppRoutes.notificationsAdmin); break;
            case 4: break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryColor), label: 'Tableau'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school, color: AppTheme.primaryColor), label: 'Doctorants'),
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description, color: AppTheme.primaryColor), label: 'Thèses'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications, color: AppTheme.primaryColor), label: 'Alertes'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child:
        Icon(icon, color: AppTheme.primaryColor, size: 17),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontSize: 10, color: AppTheme.textGray)),
      trailing: const Icon(Icons.chevron_right,
          color: Colors.grey),
      onTap: onTap,
    );
  }
}