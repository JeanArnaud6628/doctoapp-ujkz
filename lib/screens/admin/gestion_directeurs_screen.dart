import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/admin_provider.dart';
import '../../models/utilisateur_model.dart';

class GestionDirecteursScreen extends ConsumerStatefulWidget {
  const GestionDirecteursScreen({super.key});

  @override
  ConsumerState<GestionDirecteursScreen> createState() =>
      _GestionDirecteursScreenState();
}

class _GestionDirecteursScreenState
    extends ConsumerState<GestionDirecteursScreen> {
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    final directeursAsync = ref.watch(directeursAvecStats);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des Directeurs'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.ajouterDirecteur),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => setState(() => _recherche = value),
              decoration: InputDecoration(
                hintText: 'Rechercher un directeur...',
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
          // Liste
          Expanded(
            child: directeursAsync.when(
              data: (directeurs) {
                final filtered = _recherche.isEmpty
                    ? directeurs
                    : directeurs.where((d) {
                  final nom = (d['nom'] as String? ?? '').toLowerCase();
                  final prenom = (d['prenom'] as String? ?? '').toLowerCase();
                  final q = _recherche.toLowerCase();
                  return nom.contains(q) || prenom.contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_outlined,
                            size: 64, color: AppTheme.primaryColor),
                        SizedBox(height: 16),
                        Text('Aucun directeur trouvé',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: () async {
                    ref.invalidate(directeursAvecStats);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final d = filtered[index];
                      return _DirecteurCard(directeur: d);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.ajouterDirecteur),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ─── CARTE DIRECTEUR ──────────────────────────────────────────────────────

class _DirecteurCard extends StatelessWidget {
  final Map<String, dynamic> directeur;

  const _DirecteurCard({required this.directeur});

  @override
  Widget build(BuildContext context) {
    final nom = '${directeur['prenom'] ?? ''} ${directeur['nom'] ?? ''}';
    final nbDoctorants = directeur['nb_doctorants'] as int? ?? 0;
    final actif = directeur['actif'] as bool? ?? true;

    return Container(
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF0D47A1).withOpacity(0.15),
            child: Text(
              nom.isNotEmpty ? nom[0].toUpperCase() : 'D',
              style: const TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  directeur['email'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D47A1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$nbDoctorants doctorant${nbDoctorants > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF0D47A1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: actif
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        actif ? 'Actif' : 'Inactif',
                        style: TextStyle(
                          fontSize: 10,
                          color: actif ? AppTheme.primaryColor : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey[300],
            size: 20,
          ),
        ],
      ),
    );
  }
}