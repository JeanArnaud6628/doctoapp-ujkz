import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class ProrogationsDirecteurEDScreen extends ConsumerStatefulWidget {
  const ProrogationsDirecteurEDScreen({super.key});

  @override
  ConsumerState<ProrogationsDirecteurEDScreen> createState() =>
      _ProrogationsDirecteurEDScreenState();
}

class _ProrogationsDirecteurEDScreenState
    extends ConsumerState<ProrogationsDirecteurEDScreen> {
  List<Map<String, dynamic>> _demandes = [];
  bool _isLoading = true;
  String _filtre = 'en_attente';

  @override
  void initState() {
    super.initState();
    _chargerDemandes();
  }

  Future<void> _chargerDemandes() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('prorogations')
          .select(
          '''
              *,
              theses!these_id(
                id, titre,
                utilisateurs!doctorant_id(nom, prenom, ine, ecole_doctorale)
              )
              ''')
          .order('created_at', ascending: false);

      _demandes = (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Erreur chargement demandes: $e');
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
        ? _demandes
        : _demandes.where((d) => d['decision'] == _filtre).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Demandes de prorogation'),
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
                  ? 'Aucune demande en attente'
                  : 'Aucune demande traitée',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final d = filtered[index];
          return _DemandeCard(
            demande: d,
            onTraiter: () => _traiterDemande(d, 'accordee'),
            onRefuser: () => _traiterDemande(d, 'refusee'),
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
            _buildFilterChip('Accordées', 'accordee'),
            _buildFilterChip('Refusées', 'refusee'),
            _buildFilterChip('Toutes', 'tous'),
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

  Future<void> _traiterDemande(
      Map<String, dynamic> demande, String decision) async {
    try {
      await Supabase.instance.client
          .from('prorogations')
          .update({
        'decision': decision,
        'date_decision': DateTime.now().toIso8601String(),
      })
          .eq('id', demande['id']);

      // Ajouter une notification
      final these = demande['theses'] as Map<String, dynamic>?;
      final doctorant = these?['utilisateurs'] as Map<String, dynamic>?;

      if (doctorant != null) {
        await Supabase.instance.client.from('notifications').insert({
          'utilisateur_id': doctorant['id'],
          'titre': decision == 'accordee'
              ? '✅ Prorogation accordée'
              : '❌ Prorogation refusée',
          'message': decision == 'accordee'
              ? 'Votre demande de prorogation a été acceptée.'
              : 'Votre demande de prorogation a été refusée.',
          'lu': false,
        });
      }

      _chargerDemandes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decision == 'accordee'
                  ? '✅ Prorogation accordée'
                  : '❌ Prorogation refusée',
            ),
            backgroundColor:
            decision == 'accordee' ? AppTheme.primaryColor : Colors.red,
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
// CARTE DEMANDE
// ═══════════════════════════════════════════════════════════════════════════

class _DemandeCard extends StatelessWidget {
  final Map<String, dynamic> demande;
  final VoidCallback onTraiter;
  final VoidCallback onRefuser;

  const _DemandeCard({
    required this.demande,
    required this.onTraiter,
    required this.onRefuser,
  });

  @override
  Widget build(BuildContext context) {
    final these = demande['theses'] as Map<String, dynamic>?;
    final doctorant = these?['utilisateurs'] as Map<String, dynamic>?;
    final nom = doctorant != null
        ? '${doctorant['prenom'] ?? ''} ${doctorant['nom'] ?? ''}'
        : 'Inconnu';
    final ine = doctorant?['ine'] as String? ?? '';
    final ecole = doctorant?['ecole_doctorale'] as String? ?? '';
    final titre = these?['titre'] as String? ?? 'Thèse';
    final annee = demande['annee_demandee'] as int? ?? 0;

    final decision = demande['decision'] as String? ?? 'en_attente';

    Color statutColor;
    String statutLabel;

    if (decision == 'accordee') {
      statutColor = Colors.green;
      statutLabel = 'Accordée ✅';
    } else if (decision == 'refusee') {
      statutColor = Colors.red;
      statutLabel = 'Refusée ❌';
    } else {
      statutColor = Colors.orange;
      statutLabel = 'En attente ⏳';
    }

    final enAttente = decision == 'en_attente';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statutColor.withOpacity(0.3),
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
                  color: statutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  enAttente ? Icons.pending : Icons.check_circle,
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
                      '$nom ($ine)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Demande prorogation Année $annee',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textGray,
                      ),
                    ),
                    Text(
                      'Thèse: $titre',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
            'Justification: ${demande['justification'] ?? 'Non renseignée'}',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textGray,
            ),
          ),
          if (enAttente) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRefuser,
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    label: const Text('Refuser', style: TextStyle(color: Colors.red)),
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
                    label: const Text('Accorder'),
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