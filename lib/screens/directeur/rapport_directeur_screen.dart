import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class RapportDirecteurScreen extends ConsumerStatefulWidget {
  final String? rapportId;
  final String? doctorantId;

  const RapportDirecteurScreen({super.key, this.rapportId, this.doctorantId});

  @override
  ConsumerState<RapportDirecteurScreen> createState() =>
      _RapportDirecteurScreenState();
}

class _RapportDirecteurScreenState
    extends ConsumerState<RapportDirecteurScreen> {
  List<Map<String, dynamic>> _rapports = [];
  bool _isLoading = true;
  String _filtre = 'tous';
  String _doctorantNom = '';

  @override
  void initState() {
    super.initState();
    _chargerRapports();
  }

  Future<void> _chargerRapports() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      String query = '''
        *,
        utilisateurs!doctorant_id(nom, prenom, ine),
        theses!these_id(id, titre)
      ''';

      var request = Supabase.instance.client
          .from('rapports_avancement')
          .select(query);

      if (widget.doctorantId != null) {
        request = request.eq('doctorant_id', widget.doctorantId!);
      } else {
        // Récupérer les doctorants du directeur
        final theses = await Supabase.instance.client
            .from('theses')
            .select('doctorant_id')
            .eq('directeur_id', user.id);

        final doctorantIds = (theses as List)
            .map((t) => t['doctorant_id'] as String)
            .toList();

        if (doctorantIds.isNotEmpty) {
          request = request.inFilter('doctorant_id', doctorantIds);
        } else {
          _rapports = [];
          setState(() => _isLoading = false);
          return;
        }
      }

      final response = await request.order('date_depot', ascending: false);

      _rapports = (response as List).cast<Map<String, dynamic>>();

      if (_rapports.isNotEmpty) {
        final doctorant = _rapports[0]['utilisateurs'] as Map<String, dynamic>?;
        _doctorantNom = doctorant != null
            ? '${doctorant['prenom'] ?? ''} ${doctorant['nom'] ?? ''}'
            : '';
      }
    } catch (e) {
      print('Erreur chargement rapports: $e');
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
        ? _rapports
        : _rapports.where((r) => r['statut'] == _filtre).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Rapports annuels'),
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
        message: _filtre != 'tous'
            ? 'Aucun rapport avec ce statut'
            : 'Aucun rapport à valider',
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final r = filtered[index];
          return _RapportDirecteurCard(
            rapport: r,
            onValider: () => _validerRapport(r),
            onRefuser: () => _refuserRapport(r),
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

  Future<void> _validerRapport(Map<String, dynamic> rapport) async {
    try {
      await Supabase.instance.client
          .from('rapports_avancement')
          .update({
        'avis_directeur': 'favorable',
        'avis_directeur_date': DateTime.now().toIso8601String(),
      })
          .eq('id', rapport['id']);

      // Ajouter une notification
      await Supabase.instance.client.from('notifications').insert({
        'utilisateur_id': rapport['doctorant_id'],
        'titre': 'Rapport validé',
        'message': 'Votre rapport annuel a été validé par votre directeur.',
        'lu': false,
      });

      _chargerRapports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Rapport validé avec succès !'),
            backgroundColor: AppTheme.primaryColor,
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

  Future<void> _refuserRapport(Map<String, dynamic> rapport) async {
    final motifController = TextEditingController();
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser le rapport'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Motif du refus :'),
            const SizedBox(height: 8),
            TextField(
              controller: motifController,
              decoration: const InputDecoration(
                hintText: 'Expliquez les corrections à apporter...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Supabase.instance.client
                    .from('rapports_avancement')
                    .update({
                  'avis_directeur': 'defavorable',
                  'avis_directeur_date': DateTime.now().toIso8601String(),
                  'commentaire_directeur': motifController.text,
                })
                    .eq('id', rapport['id']);

                await Supabase.instance.client.from('notifications').insert({
                  'utilisateur_id': rapport['doctorant_id'],
                  'titre': 'Rapport refusé',
                  'message':
                  'Votre rapport annuel a été refusé. Motif: ${motifController.text}',
                  'lu': false,
                });

                _chargerRapports();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Rapport refusé'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                Navigator.pop(ctx);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Refuser'),
          ),
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
            context.go(AppRoutes.dashboardDirecteur);
            break;
          case 1:
            context.go(AppRoutes.doctorantsDirecteur);
            break;
          case 2:
            context.go(AppRoutes.profilDirecteur);
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
          icon: Icon(Icons.school_outlined),
          selectedIcon: Icon(Icons.school, color: AppTheme.primaryColor),
          label: 'Doctorants',
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
// CARTE RAPPORT DIRECTEUR
// ═══════════════════════════════════════════════════════════════════════════

class _RapportDirecteurCard extends StatelessWidget {
  final Map<String, dynamic> rapport;
  final VoidCallback onValider;
  final VoidCallback onRefuser;

  const _RapportDirecteurCard({
    required this.rapport,
    required this.onValider,
    required this.onRefuser,
  });

  @override
  Widget build(BuildContext context) {
    final doctorant = rapport['utilisateurs'] as Map<String, dynamic>?;
    final these = rapport['theses'] as Map<String, dynamic>?;
    final nomDoctorant = doctorant != null
        ? '${doctorant['prenom'] ?? ''} ${doctorant['nom'] ?? ''}'
        : 'Inconnu';
    final ine = doctorant?['ine'] as String? ?? '';
    final titre = these?['titre'] as String? ?? 'Thèse';
    final avisDirecteur = rapport['avis_directeur'] as String? ?? 'en_attente';

    Color statutColor;
    String statutLabel;

    if (avisDirecteur == 'favorable') {
      statutColor = Colors.green;
      statutLabel = 'Validé ✅';
    } else if (avisDirecteur == 'defavorable') {
      statutColor = Colors.red;
      statutLabel = 'Refusé ❌';
    } else {
      statutColor = Colors.orange;
      statutLabel = 'En attente ⏳';
    }

    final peutValider = avisDirecteur == 'en_attente';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statutColor.withOpacity(0.3),
          width: avisDirecteur == 'favorable' ? 1.5 : 0.5,
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
                  avisDirecteur == 'favorable'
                      ? Icons.check_circle
                      : avisDirecteur == 'defavorable'
                      ? Icons.cancel
                      : Icons.pending,
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
                  color: statutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statutLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: statutColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (peutValider) ...[
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
                    onPressed: onValider,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Valider'),
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