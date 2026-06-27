import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../models/utilisateur_model.dart';

class DashboardDirecteurScreen extends ConsumerStatefulWidget {
  const DashboardDirecteurScreen({super.key});

  @override
  ConsumerState<DashboardDirecteurScreen> createState() =>
      _DashboardDirecteurScreenState();
}

class _DashboardDirecteurScreenState
    extends ConsumerState<DashboardDirecteurScreen> {
  List<Map<String, dynamic>> _doctorants = [];
  bool _isLoading = true;
  int _nbTotal = 0;
  int _nbRapportsEnAttente = 0;
  int _nbManuscritsEnAttente = 0;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Récupérer les doctorants dont le directeur est l'utilisateur connecté
      final response = await Supabase.instance.client
          .from('theses')
          .select(
          '''
              *,
              utilisateurs!doctorant_id(
                id, nom, prenom, ine, ecole_doctorale, promotion,
                utilisateurs!doctorant_id()
              )
              ''')
          .eq('directeur_id', user.id)
          .neq('etat', 'soutenue');

      _doctorants = (response as List).cast<Map<String, dynamic>>();

      _nbTotal = _doctorants.length;

      // Compter les rapports en attente
      for (final these in _doctorants) {
        final rapports = await Supabase.instance.client
            .from('rapports_avancement')
            .select('id, statut, avis_directeur')
            .eq('these_id', these['id'])
            .neq('statut', 'valide');

        _nbRapportsEnAttente += (rapports as List).length;

        // Vérifier si le manuscrit est en attente
        final manuscrit = await Supabase.instance.client
            .from('manuscrits')
            .select('id, statut')
            .eq('these_id', these['id'])
            .eq('statut', 'en attente')
            .maybeSingle();

        if (manuscrit != null) {
          _nbManuscritsEnAttente++;
        }
      }
    } catch (e) {
      print('Erreur chargement données: $e');
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
                        'Directeur de thèse',
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
            // TODO: Notifications directeur
          },
        ),
      ],
    );
  }

  Widget _buildStats() {
    final items = [
      {'label': 'Doctorants', 'value': _nbTotal, 'color': AppTheme.primaryColor, 'icon': Icons.school},
      {'label': 'Rapports en attente', 'value': _nbRapportsEnAttente, 'color': Colors.orange, 'icon': Icons.pending},
      {'label': 'Manuscrits à valider', 'value': _nbManuscritsEnAttente, 'color': Colors.purple, 'icon': Icons.upload_file},
    ];

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final value = item['value'] as int;
          final color = item['color'] as Color;
          return Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: value > 0 ? color.withOpacity(0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: value > 0 ? color : Colors.grey,
                  size: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: value > 0 ? color : Colors.grey,
                ),
              ),
              Text(
                item['label'] as String,
                style: TextStyle(
                  fontSize: 8,
                  color: value > 0 ? color : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }).toList(),
      ),
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
                'MES DOCTORANTS',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF4A7A4A),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '$_nbTotal',
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
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.person_off_outlined,
                        size: 48, color: AppTheme.textGray),
                    SizedBox(height: 12),
                    Text(
                      'Aucun doctorant',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Vous n\'avez pas encore de doctorants à encadrer.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._doctorants.take(3).map((these) {
              final doctorant = these['utilisateurs'] as Map<String, dynamic>?;
              return _DoctorantCard(
                these: these,
                doctorant: doctorant,
                onTap: () {
                  // TODO: Ouvrir le dossier du doctorant
                },
              );
            }),
          if (_doctorants.length > 3)
            TextButton(
              onPressed: () {
                // TODO: Voir tous les doctorants
              },
              child: const Text(
                'Voir tous mes doctorants',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                ),
              ),
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
// CARTE DOCTORANT
// ═══════════════════════════════════════════════════════════════════════════

class _DoctorantCard extends StatelessWidget {
  final Map<String, dynamic> these;
  final Map<String, dynamic>? doctorant;
  final VoidCallback onTap;

  const _DoctorantCard({
    required this.these,
    required this.doctorant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nom = doctorant != null
        ? '${doctorant!['prenom'] ?? ''} ${doctorant!['nom'] ?? ''}'
        : 'Inconnu';
    final ine = doctorant?['ine'] as String? ?? '';
    final ecole = doctorant?['ecole_doctorale'] as String? ?? '';
    final etape = these['etape_actuelle'] as String? ?? 'enregistree';

    Color etapeColor;
    String etapeLabel;

    switch (etape) {
      case 'enregistree':
        etapeColor = Colors.grey;
        etapeLabel = 'Sujet enregistré';
        break;
      case 'directeur_choisi':
        etapeColor = Colors.orange;
        etapeLabel = 'En attente validation';
        break;
      case 'csi_affecte':
        etapeColor = Colors.teal;
        etapeLabel = 'CSI affecté';
        break;
      case 'rapport_annuel_1':
      case 'rapport_annuel_2':
      case 'rapport_annuel_3':
        etapeColor = Colors.orange;
        etapeLabel = 'Rapport en cours';
        break;
      case 'manuscrit_depose':
        etapeColor = Colors.purple;
        etapeLabel = 'Manuscrit à valider';
        break;
      default:
        etapeColor = AppTheme.primaryColor;
        etapeLabel = 'En cours';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBF8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: etapeColor.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: etapeColor.withOpacity(0.15),
              radius: 18,
              child: Text(
                nom.isNotEmpty ? nom[0].toUpperCase() : 'D',
                style: TextStyle(
                  color: etapeColor,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: etapeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                etapeLabel,
                style: TextStyle(
                  fontSize: 8,
                  color: etapeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}