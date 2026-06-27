import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

class StatistiquesDirecteurEDScreen extends ConsumerStatefulWidget {
  const StatistiquesDirecteurEDScreen({super.key});

  @override
  ConsumerState<StatistiquesDirecteurEDScreen> createState() =>
      _StatistiquesDirecteurEDScreenState();
}

class _StatistiquesDirecteurEDScreenState
    extends ConsumerState<StatistiquesDirecteurEDScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  String _ecole = '';

  @override
  void initState() {
    super.initState();
    _chargerStatistiques();
  }

  Future<void> _chargerStatistiques() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final userData = await Supabase.instance.client
          .from('utilisateurs')
          .select('ecole_doctorale')
          .eq('id', user.id)
          .single();

      _ecole = userData['ecole_doctorale'] as String? ?? '';

      if (_ecole.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // Récupérer les doctorants de l'école
      final doctorants = await Supabase.instance.client
          .from('utilisateurs')
          .select('id')
          .eq('role', 'doctorant')
          .eq('ecole_doctorale', _ecole);

      final doctorantIds = (doctorants as List).map((d) => d['id'] as String).toList();

      // Nombre de thèses par statut
      final theses = await Supabase.instance.client
          .from('theses')
          .select('etat')
          .eq('ecole_doctorale', _ecole);

      final thesesList = theses as List;
      final nbEnregistrees = thesesList.where((t) => t['etat'] == 'enregistree').length;
      final nbEnCours = thesesList.where((t) => t['etat'] == 'en cours').length;
      final nbEnInstruction = thesesList.where((t) => t['etat'] == 'en instruction').length;
      final nbSoutenues = thesesList.where((t) => t['etat'] == 'soutenue').length;

      // Rapports
      int nbRapportsDeposes = 0;
      int nbRapportsValides = 0;
      int nbRapportsRejetes = 0;

      if (doctorantIds.isNotEmpty) {
        final rapports = await Supabase.instance.client
            .from('rapports_avancement')
            .select('statut')
            .inFilter('doctorant_id', doctorantIds);

        final rapportsList = rapports as List;
        nbRapportsDeposes = rapportsList.length;
        nbRapportsValides = rapportsList.where((r) => r['statut'] == 'valide').length;
        nbRapportsRejetes = rapportsList.where((r) => r['statut'] == 'rejete').length;
      }

      // Soutenances
      final soutenances = await Supabase.instance.client
          .from('soutenances')
          .select('id')
          .eq('ecole_doctorale', _ecole);

      _stats = {
        'doctorants': (doctorants as List).length,
        'theses_total': thesesList.length,
        'theses_enregistrees': nbEnregistrees,
        'theses_en_cours': nbEnCours,
        'theses_en_instruction': nbEnInstruction,
        'theses_soutenues': nbSoutenues,
        'rapports_deposes': nbRapportsDeposes,
        'rapports_valides': nbRapportsValides,
        'rapports_rejetes': nbRapportsRejetes,
        'soutenances': (soutenances as List).length,
      };
    } catch (e) {
      print('Erreur chargement statistiques: $e');
    }

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
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ecole.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined,
                size: 64, color: AppTheme.textGray),
            const SizedBox(height: 16),
            const Text(
              'Aucune école doctorale associée',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Contactez l\'administration pour associer votre compte à une école.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // ─── En-tête ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'STATISTIQUES DE L\'ÉCOLE',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4A7A4A),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _ecole,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ─── Carte Doctorants ──────────────────────────────
            _StatCard(
              title: 'Doctorants',
              value: _stats['doctorants'] ?? 0,
              icon: Icons.school,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 10),

            // ─── Carte Thèses ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'THÈSES',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4A7A4A),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Total',
                          value: _stats['theses_total'] ?? 0,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'Enregistrées',
                          value: _stats['theses_enregistrees'] ?? 0,
                          color: Colors.grey,
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'En cours',
                          value: _stats['theses_en_cours'] ?? 0,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'En instruction',
                          value: _stats['theses_en_instruction'] ?? 0,
                          color: Colors.purple,
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'Soutenues',
                          value: _stats['theses_soutenues'] ?? 0,
                          color: Colors.green,
                        ),
                      ),
                      Expanded(
                        child: const SizedBox(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ─── Carte Rapports ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RAPPORTS ANNUELS',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4A7A4A),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Déposés',
                          value: _stats['rapports_deposes'] ?? 0,
                          color: Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'Validés',
                          value: _stats['rapports_valides'] ?? 0,
                          color: Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'Rejetés',
                          value: _stats['rapports_rejetes'] ?? 0,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ─── Carte Soutenances ─────────────────────────────
            _StatCard(
              title: 'Soutenances',
              value: _stats['soutenances'] ?? 0,
              icon: Icons.event,
              color: const Color(0xFFC62828),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 2),
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
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGray,
                  ),
                ),
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: AppTheme.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}