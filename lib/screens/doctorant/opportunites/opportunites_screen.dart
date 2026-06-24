import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';

class OpportunitesScreen extends StatefulWidget {
  const OpportunitesScreen({super.key});

  @override
  State<OpportunitesScreen> createState() => _OpportunitesScreenState();
}

class _OpportunitesScreenState extends State<OpportunitesScreen> {
  String _filtreActif = 'Tous';

  final List<Map<String, dynamic>> _opportunites = [
    {
      'titre': 'Séminaire – Rédaction scientifique',
      'categorie': 'Seminaire',
      'source': 'EDST – UJKZ',
      'description': 'Formation pratique sur la rédaction et la soumission d\'articles dans des revues indexées.',
      'date': '28 juin 2026',
      'couleur': const Color(0xFFE8F5E9),
      'iconColor': AppTheme.primaryColor,
      'icon': Icons.school_outlined,
    },
    {
      'titre': 'Bourse mobilité CAMES 2026',
      'categorie': 'Bourse',
      'source': 'CAMES',
      'description': 'Financement pour séjour de recherche de 3 à 6 mois. Ouvert aux doctorants en Année 2 ou 3.',
      'date': 'Limite : 15 juil.',
      'couleur': const Color(0xFFFFF3E0),
      'iconColor': const Color(0xFFC84B00),
      'icon': Icons.monetization_on_outlined,
    },
    {
      'titre': 'Colloque – Énergies renouvelables Afrique',
      'categorie': 'Conference',
      'source': 'Université de Dakar',
      'description': 'Appel à communications pour le colloque annuel sur les énergies renouvelables.',
      'date': '15 sept. 2026',
      'couleur': const Color(0xFFE3F2FD),
      'iconColor': const Color(0xFF0D47A1),
      'icon': Icons.mic_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtres = ['Tous', 'Seminaire', 'Bourse', 'Conference', 'Annonce'];
    final filtered = _filtreActif == 'Tous'
        ? _opportunites
        : _opportunites
        .where((o) => o['categorie'] == _filtreActif)
        .toList();

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
          // Filtres
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: filtres.map((f) {
                final active = f == _filtreActif;
                return GestureDetector(
                  onTap: () => setState(() => _filtreActif = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active
                          ? AppTheme.primaryColor
                          : Colors.white,
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
                        fontWeight: active
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Liste
          Expanded(
            child: ListView.builder(
              padding:
              const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final o = filtered[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFDDE8DD), width: 0.5),
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
                              color: o['couleur'] as Color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(o['icon'] as IconData,
                                color: o['iconColor'] as Color, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(o['titre'] as String,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                Text(o['source'] as String,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textGray)),
                              ],
                            ),
                          ),
                          const Icon(Icons.bookmark_border,
                              color: AppTheme.textGray, size: 20),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(o['description'] as String,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textGray),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: o['couleur'] as Color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(o['categorie'] as String,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: o['iconColor'] as Color)),
                          ),
                          Text(o['date'] as String,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textGray)),
                          const Text('Voir plus →',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 3),
    );
  }

  Widget _buildBottomNav(BuildContext context, int index) {
    return NavigationBar(
      selectedIndex: index,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE8F5E9),
      onDestinationSelected: (i) {
        switch (i) {
          case 0: context.go(AppRoutes.dashboard); break;
          case 1: context.go(AppRoutes.these); break;
          case 2: context.go(AppRoutes.notifications); break;
          case 3: context.go(AppRoutes.opportunites); break;
          case 4: context.go(AppRoutes.profil); break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppTheme.primaryColor), label: 'Accueil'),
        NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description, color: AppTheme.primaryColor), label: 'Thèse'),
        NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications, color: AppTheme.primaryColor), label: 'Alertes'),
        NavigationDestination(icon: Icon(Icons.lightbulb_outlined), selectedIcon: Icon(Icons.lightbulb, color: AppTheme.primaryColor), label: 'Opportunités'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor), label: 'Profil'),
      ],
    );
  }
}