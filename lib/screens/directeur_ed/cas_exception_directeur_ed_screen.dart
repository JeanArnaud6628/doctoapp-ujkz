import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

class CasExceptionDirecteurEDScreen extends ConsumerStatefulWidget {
  const CasExceptionDirecteurEDScreen({super.key});

  @override
  ConsumerState<CasExceptionDirecteurEDScreen> createState() =>
      _CasExceptionDirecteurEDScreenState();
}

class _CasExceptionDirecteurEDScreenState
    extends ConsumerState<CasExceptionDirecteurEDScreen> {
  List<Map<String, dynamic>> _signalements = [];
  bool _isLoading = true;
  String _filtre = 'en_attente';

  @override
  void initState() {
    super.initState();
    _chargerSignalements();
  }

  Future<void> _chargerSignalements() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('signalements')
          .select(
          '''
              *,
              utilisateurs!doctorant_id(nom, prenom, ine, ecole_doctorale),
              utilisateurs!csi_id(id, nom, prenom)
              ''')
          .order('created_at', ascending: false);

      _signalements = (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Erreur chargement signalements: $e');
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

    final filtered = _filtre == 'tous'
        ? _signalements
        : _signalements.where((s) => s['statut'] == _filtre).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Cas d\'exception'),
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
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _filtre == 'en_attente'
                  ? Icons.check_circle_outline
                  : Icons.history,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              _filtre == 'en_attente'
                  ? 'Aucun cas en attente'
                  : 'Aucun cas traité',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final s = filtered[index];
          return _CasExceptionCard(
            signalement: s,
            onTraiter: () => _traiterCas(s, 'resolu'),
            onRejeter: () => _traiterCas(s, 'rejete'),
          );
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
            _buildFilterChip('En attente', 'en_attente'),
            _buildFilterChip('Résolus', 'resolu'),
            _buildFilterChip('Rejetés', 'rejete'),
            _buildFilterChip('Tous', 'tous'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtre == value;
    return GestureDetector(
      onTap: () => setState(() => _filtre = value),
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

  Future<void> _traiterCas(Map<String, dynamic> signalement, String decision) async {
    try {
      await Supabase.instance.client
          .from('signalements')
          .update({
        'statut': decision,
        'date_traitement': DateTime.now().toIso8601String(),
      })
          .eq('id', signalement['id']);

      // Ajouter une notification
      final doctorant = signalement['utilisateurs'] as Map<String, dynamic>?;
      if (doctorant != null) {
        await Supabase.instance.client.from('notifications').insert({
          'utilisateur_id': doctorant['id'],
          'titre': decision == 'resolu'
              ? '✅ Cas résolu'
              : '❌ Cas rejeté',
          'message': decision == 'resolu'
              ? 'Le cas d\'exception vous concernant a été résolu.'
              : 'Le cas d\'exception vous concernant a été rejeté.',
          'lu': false,
        });
      }

      _chargerSignalements();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decision == 'resolu'
                  ? '✅ Cas résolu'
                  : '❌ Cas rejeté',
            ),
            backgroundColor:
            decision == 'resolu' ? AppTheme.primaryColor : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
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
// CARTE CAS EXCEPTION
// ═══════════════════════════════════════════════════════════════════════════

class _CasExceptionCard extends StatelessWidget {
  final Map<String, dynamic> signalement;
  final VoidCallback onTraiter;
  final VoidCallback onRejeter;

  const _CasExceptionCard({
    required this.signalement,
    required this.onTraiter,
    required this.onRejeter,
  });

  @override
  Widget build(BuildContext context) {
    final doctorant = signalement['utilisateurs'] as Map<String, dynamic>?;
    final csi = signalement['utilisateurs_csi_id'] as Map<String, dynamic>?;
    final nom = doctorant != null
        ? '${doctorant['prenom'] ?? ''} ${doctorant['nom'] ?? ''}'
        : 'Inconnu';
    final ine = doctorant?['ine'] as String? ?? '';
    final ecole = doctorant?['ecole_doctorale'] as String? ?? '';
    final csiNom = csi != null
        ? '${csi['prenom'] ?? ''} ${csi['nom'] ?? ''}'
        : 'CSI inconnu';

    final type = signalement['type'] as String? ?? 'autre';
    final description = signalement['description'] as String? ?? '';
    final statut = signalement['statut'] as String? ?? 'en_attente';

    Map<String, dynamic> typeConfig = {
      'conflit': {'label': 'Conflit', 'color': Colors.red, 'icon': Icons.person_off},
      'blocage_academique': {'label': 'Blocage', 'color': Colors.orange, 'icon': Icons.block},
      'retard_rapport': {'label': 'Retard rapport', 'color': Colors.red, 'icon': Icons.timer_off},
      'non_respect_engagement': {'label': 'Non-respect', 'color': Colors.purple, 'icon': Icons.warning},
      'autre': {'label': 'Autre', 'color': Colors.grey, 'icon': Icons.help_outline},
    };

    final config = typeConfig[type] ?? typeConfig['autre'];

    Color statutColor;
    String statutLabel;

    if (statut == 'resolu') {
      statutColor = Colors.green;
      statutLabel = 'Résolu ✅';
    } else if (statut == 'rejete') {
      statutColor = Colors.red;
      statutLabel = 'Rejeté ❌';
    } else {
      statutColor = Colors.orange;
      statutLabel = 'En attente ⏳';
    }

    final enAttente = statut == 'en_attente';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enAttente
              ? Colors.orange.withOpacity(0.3)
              : statutColor.withOpacity(0.3),
          width: enAttente ? 1.5 : 0.5,
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
                  color: (config['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  config['icon'] as IconData,
                  color: config['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$nom ($ine)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${config['label']} • $ecole',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textGray,
                      ),
                    ),
                    Text(
                      'Signalé par: $csiNom',
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
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textGray,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (enAttente) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRejeter,
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    label: const Text('Rejeter', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onTraiter,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Résoudre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
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
        ],
      ),
    );
  }
}