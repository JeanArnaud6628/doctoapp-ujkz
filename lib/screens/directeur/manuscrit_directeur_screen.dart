import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

class ManuscritDirecteurScreen extends ConsumerStatefulWidget {
  final String? doctorantId;

  const ManuscritDirecteurScreen({super.key, this.doctorantId});

  @override
  ConsumerState<ManuscritDirecteurScreen> createState() =>
      _ManuscritDirecteurScreenState();
}

class _ManuscritDirecteurScreenState
    extends ConsumerState<ManuscritDirecteurScreen> {
  List<Map<String, dynamic>> _manuscrits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerManuscrits();
  }

  Future<void> _chargerManuscrits() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      String query = '''
        *,
        utilisateurs!doctorant_id(nom, prenom, ine),
        theses!these_id(id, titre)
      ''';

      var request = Supabase.instance.client
          .from('manuscrits')
          .select(query);

      if (widget.doctorantId != null) {
        request = request.eq('doctorant_id', widget.doctorantId!);
      } else {
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
          _manuscrits = [];
          setState(() => _isLoading = false);
          return;
        }
      }

      final response = await request.order('created_at', ascending: false);

      _manuscrits = (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Erreur chargement manuscrits: $e');
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

    final enAttente = _manuscrits.where((m) => m['statut'] == 'en attente').toList();
    final autres = _manuscrits.where((m) => m['statut'] != 'en attente').toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Manuscrits à valider'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _manuscrits.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file_outlined,
                size: 64, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Aucun manuscrit',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les manuscrits de vos doctorants apparaîtront ici.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textGray,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _manuscrits.length,
        itemBuilder: (context, index) {
          final m = _manuscrits[index];
          final estEnAttente = m['statut'] == 'en attente';
          return _ManuscritDirecteurCard(
            manuscrit: m,
            estEnAttente: estEnAttente,
            onValider: () => _validerManuscrit(m),
            onRefuser: () => _refuserManuscrit(m),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Future<void> _validerManuscrit(Map<String, dynamic> manuscrit) async {
    try {
      await Supabase.instance.client
          .from('manuscrits')
          .update({
        'statut': 'valide',
        'validation_admin': true,
      })
          .eq('id', manuscrit['id']);

      // Mettre à jour la thèse
      await Supabase.instance.client
          .from('theses')
          .update({
        'quitus_directeur': true,
        'etape_actuelle': 'quitus_directeur',
      })
          .eq('id', manuscrit['these_id']);

      // Ajouter une notification
      await Supabase.instance.client.from('notifications').insert({
        'utilisateur_id': manuscrit['doctorant_id'],
        'titre': 'Manuscrit validé',
        'message': 'Votre manuscrit a été validé par votre directeur.',
        'lu': false,
      });

      _chargerManuscrits();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Manuscrit validé avec succès !'),
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

  Future<void> _refuserManuscrit(Map<String, dynamic> manuscrit) async {
    final motifController = TextEditingController();
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser le manuscrit'),
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
                    .from('manuscrits')
                    .update({
                  'statut': 'rejete',
                })
                    .eq('id', manuscrit['id']);

                await Supabase.instance.client.from('notifications').insert({
                  'utilisateur_id': manuscrit['doctorant_id'],
                  'titre': 'Manuscrit refusé',
                  'message':
                  'Votre manuscrit a été refusé. Motif: ${motifController.text}',
                  'lu': false,
                });

                _chargerManuscrits();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Manuscrit refusé'),
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
// CARTE MANUSCRIT DIRECTEUR
// ═══════════════════════════════════════════════════════════════════════════

class _ManuscritDirecteurCard extends StatelessWidget {
  final Map<String, dynamic> manuscrit;
  final bool estEnAttente;
  final VoidCallback onValider;
  final VoidCallback onRefuser;

  const _ManuscritDirecteurCard({
    required this.manuscrit,
    required this.estEnAttente,
    required this.onValider,
    required this.onRefuser,
  });

  @override
  Widget build(BuildContext context) {
    final doctorant = manuscrit['utilisateurs'] as Map<String, dynamic>?;
    final these = manuscrit['theses'] as Map<String, dynamic>?;
    final nomDoctorant = doctorant != null
        ? '${doctorant['prenom'] ?? ''} ${doctorant['nom'] ?? ''}'
        : 'Inconnu';
    final ine = doctorant?['ine'] as String? ?? '';
    final titre = these?['titre'] as String? ?? 'Thèse';

    Color statutColor;
    String statutLabel;

    if (manuscrit['statut'] == 'valide') {
      statutColor = Colors.green;
      statutLabel = 'Validé ✅';
    } else if (manuscrit['statut'] == 'rejete') {
      statutColor = Colors.red;
      statutLabel = 'Refusé ❌';
    } else {
      statutColor = Colors.orange;
      statutLabel = 'En attente ⏳';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: estEnAttente
              ? Colors.purple.withOpacity(0.3)
              : statutColor.withOpacity(0.3),
          width: estEnAttente ? 1.5 : 0.5,
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
                  color: estEnAttente
                      ? Colors.purple.withOpacity(0.1)
                      : statutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  estEnAttente ? Icons.upload_file : Icons.check_circle,
                  color: estEnAttente ? Colors.purple : statutColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manuscrit['titre'] as String? ?? 'Manuscrit',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$nomDoctorant ($ine)',
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
                  color: estEnAttente
                      ? Colors.purple.withOpacity(0.1)
                      : statutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statutLabel,
                  style: TextStyle(
                    fontSize: 9,
                    color: estEnAttente ? Colors.purple : statutColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (estEnAttente) ...[
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