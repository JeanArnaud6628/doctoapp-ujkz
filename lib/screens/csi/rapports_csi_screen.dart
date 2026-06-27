import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

class RapportsCSIScreen extends ConsumerStatefulWidget {
  const RapportsCSIScreen({super.key});

  @override
  ConsumerState<RapportsCSIScreen> createState() => _RapportsCSIScreenState();
}

class _RapportsCSIScreenState extends ConsumerState<RapportsCSIScreen> {
  List<Map<String, dynamic>> _rapports = [];
  bool _isLoading = true;
  String _filtreStatut = 'tous';

  @override
  void initState() {
    super.initState();
    _chargerRapports();
  }

  Future<void> _chargerRapports() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Récupérer les doctorants affectés au CSI
      final affectations = await Supabase.instance.client
          .from('affectations_csi')
          .select('these_id')
          .eq('csi_id', user.id)
          .eq('actif', true);

      final theseIds = (affectations as List).map((a) => a['these_id'] as String).toList();

      if (theseIds.isNotEmpty) {
        final rapports = await Supabase.instance.client
            .from('rapports_avancement')
            .select('*, utilisateurs!doctorant_id(nom, prenom, ine)')
            .inFilter('these_id', theseIds)
            .order('date_depot', ascending: false);

        _rapports = (rapports as List).cast<Map<String, dynamic>>();
      }
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

    final filtered = _filtrerRapports();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Rapports des doctorants'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: _buildFiltres(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
          ? _EmptyState(
        message: _filtreStatut != 'tous'
            ? 'Aucun rapport avec ce statut'
            : 'Aucun rapport disponible',
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final r = filtered[index];
          return _RapportCard(rapport: r);
        },
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Widget _buildFiltres() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tous', 'tous'),
            _buildFilterChip('En attente', 'en attente'),
            _buildFilterChip('Validés', 'valide'),
            _buildFilterChip('Rejetés', 'rejete'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtreStatut == value;
    return GestureDetector(
      onTap: () => setState(() => _filtreStatut = value),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filtrerRapports() {
    if (_filtreStatut == 'tous') return _rapports;
    return _rapports.where((r) => r['statut'] == _filtreStatut).toList();
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
// CARTE RAPPORT
// ═══════════════════════════════════════════════════════════════════════════

class _RapportCard extends StatelessWidget {
  final Map<String, dynamic> rapport;

  const _RapportCard({required this.rapport});

  @override
  Widget build(BuildContext context) {
    final utilisateur = rapport['utilisateurs'] as Map<String, dynamic>?;
    final nomDoctorant = utilisateur != null
        ? '${utilisateur['prenom'] ?? ''} ${utilisateur['nom'] ?? ''}'
        : 'Inconnu';
    final ine = utilisateur?['ine'] as String? ?? '';

    final statut = rapport['statut'] as String? ?? 'en attente';
    final avisCsi = rapport['avis_csi'] as String? ?? 'en_attente';

    Color statutColor;
    String statutLabel;
    Color avisColor;
    String avisLabel;

    if (statut == 'valide') {
      statutColor = Colors.green;
      statutLabel = 'Validé ✅';
    } else if (statut == 'rejete') {
      statutColor = Colors.red;
      statutLabel = 'Rejeté ❌';
    } else {
      statutColor = Colors.orange;
      statutLabel = 'En attente ⏳';
    }

    if (avisCsi == 'favorable') {
      avisColor = Colors.green;
      avisLabel = 'Favorable ✅';
    } else if (avisCsi == 'defavorable') {
      avisColor = Colors.red;
      avisLabel = 'Défavorable ❌';
    } else if (avisCsi == 'signalement') {
      avisColor = Colors.red;
      avisLabel = 'Signalement ⚠️';
    } else {
      avisColor = Colors.orange;
      avisLabel = 'En attente ⏳';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statutColor.withOpacity(0.3),
          width: statut == 'valide' ? 1.5 : 0.5,
        ),
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
                  color: statutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  statut == 'valide' ? Icons.check_circle : Icons.assignment,
                  color: statutColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rapport['titre'] as String? ?? 'Rapport Année ${rapport['annee']}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Année ${rapport['annee']} • $nomDoctorant ($ine)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textGray,
                      ),
                    ),
                    Text(
                      'Déposé le ${rapport['date_depot'] ?? '–'}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statutLabel,
                  style: TextStyle(
                    fontSize: 9,
                    color: statutColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Mon avis: ',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textGray,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: avisColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  avisLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: avisColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (statut != 'valide' && statut != 'rejete')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Ouvrir l'écran d'avis
                    },
                    icon: const Icon(Icons.rate_review, size: 16),
                    label: const Text('Donner mon avis'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Organiser entretien
                    },
                    icon: const Icon(Icons.people, size: 16),
                    label: const Text('Entretien'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}