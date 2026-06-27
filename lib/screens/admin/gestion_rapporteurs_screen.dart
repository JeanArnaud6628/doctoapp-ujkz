import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/admin_provider.dart';

class GestionRapporteursScreen extends ConsumerStatefulWidget {
  const GestionRapporteursScreen({super.key});

  @override
  ConsumerState<GestionRapporteursScreen> createState() =>
      _GestionRapporteursScreenState();
}

class _GestionRapporteursScreenState
    extends ConsumerState<GestionRapporteursScreen> {
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    final rapporteursAsync = ref.watch(rapporteursAvecStats);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des Rapporteurs'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.ajouterRapporteur),
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
                hintText: 'Rechercher un rapporteur...',
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
            child: rapporteursAsync.when(
              data: (rapporteurs) {
                final filtered = _recherche.isEmpty
                    ? rapporteurs
                    : rapporteurs.where((r) {
                  final nom = (r['nom'] as String? ?? '').toLowerCase();
                  final prenom = (r['prenom'] as String? ?? '').toLowerCase();
                  final q = _recherche.toLowerCase();
                  return nom.contains(q) || prenom.contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined,
                            size: 64, color: AppTheme.primaryColor),
                        SizedBox(height: 16),
                        Text('Aucun rapporteur trouvé',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: () async {
                    ref.invalidate(rapporteursAvecStats);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final r = filtered[index];
                      return _RapporteurCard(rapporteur: r);
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
        onPressed: () => context.push(AppRoutes.ajouterRapporteur),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ─── CARTE RAPPORTEUR ────────────────────────────────────────────────────

class _RapporteurCard extends StatelessWidget {
  final Map<String, dynamic> rapporteur;

  const _RapporteurCard({required this.rapporteur});

  @override
  Widget build(BuildContext context) {
    final nom = '${rapporteur['prenom'] ?? ''} ${rapporteur['nom'] ?? ''}';
    final nbTotal = rapporteur['nb_total'] as int? ?? 0;
    final nbEnCours = rapporteur['nb_en_cours'] as int? ?? 0;
    final nbTermines = rapporteur['nb_termines'] as int? ?? 0;
    final estLibre = rapporteur['est_libre'] as bool? ?? true;
    final actif = rapporteur['actif'] as bool? ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: estLibre ? AppTheme.primaryColor : Colors.grey[300]!,
          width: estLibre ? 1.5 : 0.5,
        ),
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
            backgroundColor: const Color(0xFF6A1B9A).withOpacity(0.15),
            child: Text(
              nom.isNotEmpty ? nom[0].toUpperCase() : 'R',
              style: const TextStyle(
                color: Color(0xFF6A1B9A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      nom,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (estLibre) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Libre',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  rapporteur['email'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _StatBadge(
                      label: 'Total',
                      value: nbTotal.toString(),
                      color: const Color(0xFF6A1B9A),
                    ),
                    const SizedBox(width: 6),
                    _StatBadge(
                      label: 'En cours',
                      value: nbEnCours.toString(),
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    _StatBadge(
                      label: 'Terminés',
                      value: nbTermines.toString(),
                      color: Colors.green,
                    ),
                    const SizedBox(width: 6),
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

// ─── STAT BADGE ───────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value $label',
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}