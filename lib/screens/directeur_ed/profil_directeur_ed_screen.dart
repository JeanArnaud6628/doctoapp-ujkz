import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../models/utilisateur_model.dart';

class ProfilDirecteurEDScreen extends ConsumerWidget {
  const ProfilDirecteurEDScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.utilisateur;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user.initiales,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user.nomComplet,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Directeur École Doctorale',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.ecoleDoctorale ?? 'UJKZ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
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
                _InfoCard(
                  title: 'INFORMATIONS PERSONNELLES',
                  children: [
                    _InfoRow('Nom', user.nom),
                    _InfoRow('Prénom', user.prenom),
                    _InfoRow('Email', user.email),
                    _InfoRow('Téléphone', user.telephone ?? 'Non défini'),
                    _InfoRow('École doctorale', user.ecoleDoctorale ?? 'Non définie'),
                    _InfoRow('Statut', user.statutLibelle),
                  ],
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFDDE8DD),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIONS RAPIDES',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4A7A4A),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        Icons.pending,
                        'Prorogations',
                        'Gérer les demandes de prorogation',
                            () => context.go(AppRoutes.prorogationsDirecteurED),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        Icons.warning,
                        'Cas d\'exception',
                        'Gérer les cas signalés',
                            () => context.go(AppRoutes.casExceptionDirecteurED),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        Icons.bar_chart,
                        'Statistiques',
                        'Consulter les indicateurs',
                            () => context.go(AppRoutes.statistiquesDirecteurED),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).deconnecter();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Color(0xFFFFCDD2)),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text(
                    'Se déconnecter',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 3),
    );
  }

  Widget _buildMenuItem(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      ) {
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
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.textGray,
        ),
      ),
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
          case 0:
            context.go(AppRoutes.dashboardDirecteurED);
            break;
          case 1:
            context.go(AppRoutes.prorogationsDirecteurED);
            break;
          case 2:
            context.go(AppRoutes.statistiquesDirecteurED);
            break;
          case 3:
            context.go(AppRoutes.profilDirecteurED);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryColor),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.pending_outlined),
          selectedIcon: Icon(Icons.pending, color: AppTheme.primaryColor),
          label: 'Prorogations',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart, color: AppTheme.primaryColor),
          label: 'Stats',
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
// WIDGETS COMMUNS
// ═══════════════════════════════════════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDDE8DD),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF4A7A4A),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}