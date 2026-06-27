import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';

class OpportunitesScreen extends ConsumerStatefulWidget {
  const OpportunitesScreen({super.key});

  @override
  ConsumerState<OpportunitesScreen> createState() =>
      _OpportunitesScreenState();
}

class _OpportunitesScreenState extends ConsumerState<OpportunitesScreen> {
  String _filtreActif = 'Tous';
  String _recherche = '';

  final List<String> _filtres = ['Tous', 'Seminaire', 'Bourse', 'Conference', 'Annonce'];

  // TODO: Remplacer par des données réelles depuis Supabase
  final List<Map<String, dynamic>> _opportunites = [
    {
      'id': '1',
      'titre': 'Séminaire – Rédaction scientifique',
      'categorie': 'Seminaire',
      'source': 'EDST – UJKZ',
      'description': 'Formation pratique sur la rédaction et la soumission d\'articles dans des revues indexées.',
      'date': '28 juin 2026',
      'couleur': const Color(0xFFE8F5E9),
      'iconColor': AppTheme.primaryColor,
      'icon': Icons.school_outlined,
      'sauvegardee': false,
    },
    {
      'id': '2',
      'titre': 'Bourse mobilité CAMES 2026',
      'categorie': 'Bourse',
      'source': 'CAMES',
      'description': 'Financement pour séjour de recherche de 3 à 6 mois. Ouvert aux doctorants en Année 2 ou 3.',
      'date': 'Limite : 15 juil.',
      'couleur': const Color(0xFFFFF3E0),
      'iconColor': const Color(0xFFC84B00),
      'icon': Icons.monetization_on_outlined,
      'sauvegardee': false,
    },
    {
      'id': '3',
      'titre': 'Colloque – Énergies renouvelables Afrique',
      'categorie': 'Conference',
      'source': 'Université de Dakar',
      'description': 'Appel à communications pour le colloque annuel sur les énergies renouvelables.',
      'date': '15 sept. 2026',
      'couleur': const Color(0xFFE3F2FD),
      'iconColor': const Color(0xFF0D47A1),
      'icon': Icons.mic_outlined,
      'sauvegardee': false,
    },
    {
      'id': '4',
      'titre': 'Appel à projets – Recherche Sahel',
      'categorie': 'Annonce',
      'source': 'Institut de Recherche Sahel',
      'description': 'Financement pour des projets de recherche sur les thématiques liées au Sahel.',
      'date': '30 août 2026',
      'couleur': const Color(0xFFFCE4EC),
      'iconColor': const Color(0xFFC62828),
      'icon': Icons.assignment_outlined,
      'sauvegardee': false,
    },
    {
      'id': '5',
      'titre': 'Bourse post-doctorale France-Burkina',
      'categorie': 'Bourse',
      'source': 'Ambassade de France',
      'description': 'Bourse pour séjour post-doctoral en France dans le cadre de la coopération scientifique.',
      'date': 'Limite : 31 oct.',
      'couleur': const Color(0xFFFFF3E0),
      'iconColor': const Color(0xFFC84B00),
      'icon': Icons.monetization_on_outlined,
      'sauvegardee': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.utilisateur;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filtered = _filtrerOpportunites();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Opportunités'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ─── Barre de recherche ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => setState(() => _recherche = value),
              decoration: InputDecoration(
                hintText: 'Rechercher une opportunité...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC8DFC8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC8DFC8)),
                ),
              ),
            ),
          ),

          // ─── Filtres ─────────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _filtres.map((f) {
                final active = f == _filtreActif;
                return GestureDetector(
                  onTap: () => setState(() => _filtreActif = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? AppTheme.primaryColor
                            : const Color(0xFFDDE8DD),
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 12,
                        color: active ? Colors.white : Colors.grey,
                        fontWeight: active ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),

          // ─── Liste ──────────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off_outlined,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune opportunité trouvée',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Essayez de modifier votre recherche ou vos filtres',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () async {
                // TODO: Recharger les opportunités depuis Supabase
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final o = filtered[index];
                  return _buildOpportuniteCard(o);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 3),
    );
  }

  List<Map<String, dynamic>> _filtrerOpportunites() {
    var result = _opportunites;

    if (_filtreActif != 'Tous') {
      result = result.where((o) => o['categorie'] == _filtreActif).toList();
    }

    if (_recherche.isNotEmpty) {
      final q = _recherche.toLowerCase();
      result = result.where((o) {
        final titre = (o['titre'] as String).toLowerCase();
        final description = (o['description'] as String).toLowerCase();
        final source = (o['source'] as String).toLowerCase();
        return titre.contains(q) ||
            description.contains(q) ||
            source.contains(q);
      }).toList();
    }

    return result;
  }

  Widget _buildOpportuniteCard(Map<String, dynamic> o) {
    final isSaved = o['sauvegardee'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDDE8DD),
          width: 0.5,
        ),
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
          // ─── En-tête ────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: o['couleur'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  o['icon'] as IconData,
                  color: o['iconColor'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o['titre'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      o['source'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    final index = _opportunites.indexWhere((item) => item['id'] == o['id']);
                    if (index != -1) {
                      _opportunites[index]['sauvegardee'] = !isSaved;
                    }
                  });
                },
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? AppTheme.primaryColor : AppTheme.textGray,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ─── Description ───────────────────────────────────────────────
          Text(
            o['description'] as String,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textGray,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // ─── Footer ─────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: o['couleur'] as Color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  o['categorie'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: o['iconColor'] as Color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                o['date'] as String,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textGray,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Afficher les détails de l'opportunité
                },
                child: const Text(
                  'Voir plus →',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
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
            context.go(AppRoutes.dashboard);
            break;
          case 1:
            context.go(AppRoutes.these);
            break;
          case 2:
            context.go(AppRoutes.notifications);
            break;
          case 3:
            context.go(AppRoutes.opportunites);
            break;
          case 4:
            context.go(AppRoutes.profil);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppTheme.primaryColor),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description, color: AppTheme.primaryColor),
          label: 'Thèse',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications, color: AppTheme.primaryColor),
          label: 'Alertes',
        ),
        NavigationDestination(
          icon: Icon(Icons.lightbulb_outlined),
          selectedIcon: Icon(Icons.lightbulb, color: AppTheme.primaryColor),
          label: 'Opportunités',
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