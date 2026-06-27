import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

class DoctorantsDirecteurScreen extends ConsumerStatefulWidget {
  const DoctorantsDirecteurScreen({super.key});

  @override
  ConsumerState<DoctorantsDirecteurScreen> createState() =>
      _DoctorantsDirecteurScreenState();
}

class _DoctorantsDirecteurScreenState
    extends ConsumerState<DoctorantsDirecteurScreen> {
  List<Map<String, dynamic>> _doctorants = [];
  bool _isLoading = true;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _chargerDoctorants();
  }

  Future<void> _chargerDoctorants() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('theses')
          .select(
          '''
              *,
              utilisateurs!doctorant_id(
                id, nom, prenom, ine, ecole_doctorale, promotion
              )
              ''')
          .eq('directeur_id', user.id)
          .neq('etat', 'soutenue')
          .order('created_at', ascending: false);

      _doctorants = (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Erreur chargement doctorants: $e');
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

    final filtered = _recherche.isEmpty
        ? _doctorants
        : _doctorants.where((these) {
      final doctorant = these['utilisateurs'] as Map<String, dynamic>?;
      final nom = doctorant != null
          ? '${doctorant['prenom'] ?? ''} ${doctorant['nom'] ?? ''}'
          : '';
      return nom.toLowerCase().contains(_recherche.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mes doctorants'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() => _recherche = value),
              decoration: InputDecoration(
                hintText: 'Rechercher un doctorant...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.6),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined,
                size: 64, color: AppTheme.primaryColor),
            SizedBox(height: 16),
            Text(
              'Aucun doctorant trouvé',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final these = filtered[index];
          final doctorant = these['utilisateurs'] as Map<String, dynamic>?;
          return _DoctorantCardComplet(
            these: these,
            doctorant: doctorant,
            onTap: () {
              // TODO: Ouvrir le dossier du doctorant
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
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
// CARTE DOCTORANT COMPLET
// ═══════════════════════════════════════════════════════════════════════════

class _DoctorantCardComplet extends StatelessWidget {
  final Map<String, dynamic> these;
  final Map<String, dynamic>? doctorant;
  final VoidCallback onTap;

  const _DoctorantCardComplet({
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
    final promotion = doctorant?['promotion'] as String? ?? '';
    final titre = these['titre'] as String? ?? '';
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
      case 'directeur_valide':
        etapeColor = Colors.blue;
        etapeLabel = 'Directeur validé';
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: etapeColor.withOpacity(0.15),
                  radius: 20,
                  child: Text(
                    nom.isNotEmpty ? nom[0].toUpperCase() : 'D',
                    style: TextStyle(
                      color: etapeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'INE: $ine • $ecole',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textGray,
                        ),
                      ),
                      if (promotion.isNotEmpty)
                        Text(
                          'Promotion: $promotion',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textGray,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: etapeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    etapeLabel,
                    style: TextStyle(
                      fontSize: 9,
                      color: etapeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (titre.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Thèse: $titre',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textGray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}