import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../models/utilisateur_model.dart';

class DashboardCSIScreen extends ConsumerStatefulWidget {
  const DashboardCSIScreen({super.key});

  @override
  ConsumerState<DashboardCSIScreen> createState() =>
      _DashboardCSIScreenState();
}

class _DashboardCSIScreenState extends ConsumerState<DashboardCSIScreen> {
  List<Map<String, dynamic>> _doctorants = [];
  bool _isLoading = true;
  int _nbAvisEnAttente = 0;
  int _nbEntretiens = 0;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Récupérer les doctorants affectés au CSI
      final affectations = await Supabase.instance.client
          .from('affectations_csi')
          .select('*, theses!these_id(id, titre, etape_actuelle, doctorant_id)')
          .eq('csi_id', user.id)
          .eq('actif', true);

      final doctorantsIds = (affectations as List).map((a) => a['theses']['doctorant_id'] as String).toList();

      if (doctorantsIds.isNotEmpty) {
        final doctorants = await Supabase.instance.client
            .from('utilisateurs')
            .select()
            .inFilter('id', doctorantsIds);

        _doctorants = (doctorants as List).cast<Map<String, dynamic>>();
      }

      // Compter les avis en attente
      // TODO: Compter les rapports sans avis CSI
      _nbAvisEnAttente = 0;

      // Compter les entretiens
      _nbEntretiens = 0;

    } catch (_) {}

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.utilisateur;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          _buildHeader(user),
          SliverPadding(
            padding: const EdgeInsets.all(14),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStats(),
                const SizedBox(height: 14),
                _buildDoctorantsList(),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 0),
    );
  }

  Widget _buildHeader(UtilisateurModel user) {
    return SliverAppBar(
      expandedHeight: 140,
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
                      const Text(
                        'Membre CSI',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
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
          onPressed: () {
            // TODO: Notifications CSI
          },
        ),
      ],
    );
  }

  Widget _buildStats() {
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Doctorants suivis',
            value: _doctorants.length.toString(),
            icon: Icons.school,
            color: AppTheme.primaryColor,
          ),
          _StatItem(
            label: 'Avis en attente',
            value: _nbAvisEnAttente.toString(),
            icon: Icons.pending,
            color: Colors.orange,
          ),
          _StatItem(
            label: 'Entretiens',
            value: _nbEntretiens.toString(),
            icon: Icons.people,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _StatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AppTheme.textGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDoctorantsList() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DOCTORANTS SUIVIS',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF4A7A4A),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${_doctorants.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_doctorants.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Aucun doctorant affecté pour le moment',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textGray,
                  ),
                ),
              ),
            )
          else
            ..._doctorants.map((d) {
              return _DoctorantCard(
                doctorant: d,
                onTap: () {
                  // TODO: Ouvrir le dossier du doctorant
                },
              );
            }),
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
          case 0:
            context.go(AppRoutes.dashboardCSI);
            break;
          case 1:
            context.go(AppRoutes.rapportsCSI);
            break;
          case 2:
            context.go(AppRoutes.profilCSI);
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
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment, color: AppTheme.primaryColor),
          label: 'Rapports',
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
// CARTE DOCTORANT
// ═══════════════════════════════════════════════════════════════════════════

class _DoctorantCard extends StatelessWidget {
  final Map<String, dynamic> doctorant;
  final VoidCallback onTap;

  const _DoctorantCard({
    required this.doctorant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nom = '${doctorant['prenom'] ?? ''} ${doctorant['nom'] ?? ''}';
    final ine = doctorant['ine'] as String? ?? '';
    final ecole = doctorant['ecole_doctorale'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBF8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE8EEE8),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
              radius: 18,
              child: Text(
                nom.isNotEmpty ? nom[0].toUpperCase() : 'D',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'INE: $ine • $ecole',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[300],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}