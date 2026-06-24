import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const Scaffold();

    final email = user.email ?? '';
    final ine = email.split('@')[0].toUpperCase();
    final initiales = ine.length >= 2 ? ine.substring(0, 2) : ine;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
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
                    Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 3),
                          ),
                          child: Center(
                            child: Text(
                              initiales,
                              style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFFC8DFC8),
                                  width: 1.5),
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 12,
                                color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(ine,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                    Text(email,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Doctorant – UJKZ',
                        style: TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
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
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFDDE8DD), width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('STATISTIQUES DOCTORALES',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF4A7A4A),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildStatItem('0', 'Année en cours'),
                          const SizedBox(width: 8),
                          _buildStatItem('0/30', 'Crédits validés'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatItem('0', 'Rapports déposés'),
                          const SizedBox(width: 8),
                          _buildStatItem('0', 'Jours de thèse'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Menu
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFDDE8DD), width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MON ESPACE',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF4A7A4A),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                          Icons.description_outlined,
                          'Mes documents',
                          'Protocole, rapports, manuscrit',
                              () {}),
                      _buildDivider(),
                      _buildMenuItem(
                          Icons.workspace_premium_outlined,
                          'Mes attestations',
                          'Crédits de formation validés',
                              () {}),
                      _buildDivider(),
                      _buildMenuItem(
                          Icons.bookmark_outline,
                          'Opportunités sauvegardées',
                          '0 éléments',
                              () {}),
                      _buildDivider(),
                      _buildMenuItem(
                          Icons.lock_outline,
                          'Changer le mot de passe',
                          'Sécurité du compte',
                              () {}),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Déconnexion
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).deconnecter();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Color(0xFFFFCDD2)),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 4),
    );
  }

  Widget _buildStatItem(String value, String label) {
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
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 17),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 10, color: AppTheme.textGray)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFFF0F0F0));
  }

  Widget _buildBottomNav(BuildContext context, int index) {
    return NavigationBar(
      selectedIndex: index,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE8F5E9),
      onDestinationSelected: (i) {
        switch (i) {
          case 0: context.go(AppRoutes.dashboard); break;
          case 1: context.go(AppRoutes.these); break;
          case 2: context.go(AppRoutes.notifications); break;
          case 3: context.go(AppRoutes.opportunites); break;
          case 4: context.go(AppRoutes.profil); break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppTheme.primaryColor), label: 'Accueil'),
        NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description, color: AppTheme.primaryColor), label: 'Thèse'),
        NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications, color: AppTheme.primaryColor), label: 'Alertes'),
        NavigationDestination(icon: Icon(Icons.lightbulb_outlined), selectedIcon: Icon(Icons.lightbulb, color: AppTheme.primaryColor), label: 'Opportunités'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor), label: 'Profil'),
      ],
    );
  }
}