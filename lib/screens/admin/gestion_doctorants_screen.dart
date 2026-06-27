import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/admin_provider.dart';
import '../../models/utilisateur_model.dart';

class GestionDoctorantsScreen extends ConsumerStatefulWidget {
  const GestionDoctorantsScreen({super.key});

  @override
  ConsumerState<GestionDoctorantsScreen> createState() =>
      _GestionDoctorantsScreenState();
}

class _GestionDoctorantsScreenState
    extends ConsumerState<GestionDoctorantsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _recherche = '';
  String _filtreStatut = 'tous';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statsDoctorantsProvider);
    final doctorantsAsync = ref.watch(doctorantsProvider);
    final enAttenteAsync = ref.watch(doctorantsEnAttenteProvider);
    final actifsAsync = ref.watch(doctorantsActifsProvider);
    final bloquesAsync = ref.watch(doctorantsBloquesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des Doctorants'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.ajouterDoctorant),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.ajouterDoctorant),
            icon: const Icon(Icons.upload_file),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              statsAsync.when(
                data: (stats) => _buildStats(stats),
                loading: () => const SizedBox(height: 50),
                error: (_, __) => const SizedBox(height: 50),
              ),
              _buildFilterTabs(),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => setState(() => _recherche = value),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, prénom ou INE...',
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
          Expanded(
            child: _buildList(doctorantsAsync, enAttenteAsync, actifsAsync, bloquesAsync),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.ajouterDoctorant),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ─── STATISTIQUES ─────────────────────────────────────────────────────────

  Widget _buildStats(Map<String, int> stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _StatChip(
            label: 'Total',
            value: stats['total'] ?? 0,
            color: AppTheme.primaryColor,
            isSelected: _filtreStatut == 'tous',
            onTap: () => setState(() => _filtreStatut = 'tous'),
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Actifs',
            value: stats['actifs'] ?? 0,
            color: const Color(0xFF4CAF50),
            isSelected: _filtreStatut == 'actif',
            onTap: () => setState(() => _filtreStatut = 'actif'),
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'En attente',
            value: stats['en_attente'] ?? 0,
            color: const Color(0xFFFF9800),
            isSelected: _filtreStatut == 'en_attente',
            onTap: () => setState(() => _filtreStatut = 'en_attente'),
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Bloqués',
            value: stats['bloques'] ?? 0,
            color: const Color(0xFFF44336),
            isSelected: _filtreStatut == 'bloque',
            onTap: () => setState(() => _filtreStatut = 'bloque'),
          ),
        ],
      ),
    );
  }

  Widget _StatChip({
    required String label,
    required int value,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FILTRES ─────────────────────────────────────────────────────────────

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryColor,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              setState(() => _filtreStatut = 'tous');
              break;
            case 1:
              setState(() => _filtreStatut = 'actif');
              break;
            case 2:
              setState(() => _filtreStatut = 'en_attente');
              break;
            case 3:
              setState(() => _filtreStatut = 'bloque');
              break;
          }
        },
        tabs: const [
          Tab(text: 'Tous'),
          Tab(text: 'Actifs'),
          Tab(text: 'En attente'),
          Tab(text: 'Bloqués'),
        ],
      ),
    );
  }

  // ─── LISTE ───────────────────────────────────────────────────────────────

  Widget _buildList(
      AsyncValue<List<UtilisateurModel>> doctorantsAsync,
      AsyncValue<List<UtilisateurModel>> enAttenteAsync,
      AsyncValue<List<UtilisateurModel>> actifsAsync,
      AsyncValue<List<UtilisateurModel>> bloquesAsync,
      ) {
    AsyncValue<List<UtilisateurModel>> asyncData;

    switch (_filtreStatut) {
      case 'actif':
        asyncData = actifsAsync;
        break;
      case 'en_attente':
        asyncData = enAttenteAsync;
        break;
      case 'bloque':
        asyncData = bloquesAsync;
        break;
      default:
        asyncData = doctorantsAsync;
    }

    return asyncData.when(
      data: (liste) {
        final filtered = _recherche.isEmpty
            ? liste
            : liste.where((u) {
          final nom = u.nom.toLowerCase();
          final prenom = u.prenom.toLowerCase();
          final ine = u.ine?.toLowerCase() ?? '';
          final q = _recherche.toLowerCase();
          return nom.contains(q) || prenom.contains(q) || ine.contains(q);
        }).toList();

        if (filtered.isEmpty) {
          return _EmptyState(
            message: _filtreStatut == 'en_attente'
                ? 'Aucun doctorant en attente d\'activation'
                : _filtreStatut == 'actif'
                ? 'Aucun doctorant actif'
                : _filtreStatut == 'bloque'
                ? 'Aucun doctorant bloqué'
                : 'Aucun doctorant trouvé',
          );
        }

        return RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
            ref.invalidate(doctorantsProvider);
            ref.invalidate(doctorantsEnAttenteProvider);
            ref.invalidate(doctorantsActifsProvider);
            ref.invalidate(doctorantsBloquesProvider);
            ref.invalidate(statsDoctorantsProvider);
            ref.invalidate(adminStatsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final u = filtered[index];
              return _DoctorantCard(doctorant: u);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CARTE DOCTORANT
// ═══════════════════════════════════════════════════════════════════════════

class _DoctorantCard extends StatelessWidget {
  final UtilisateurModel doctorant;

  const _DoctorantCard({required this.doctorant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '${AppRoutes.profilDoctorantAdmin}/${doctorant.id}',
      ),
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: doctorant.estEnAttente
                  ? const Color(0xFFFF9800).withOpacity(0.2)
                  : doctorant.estActif
                  ? AppTheme.primaryColor.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              child: Text(
                doctorant.initiales,
                style: TextStyle(
                  color: doctorant.estEnAttente
                      ? const Color(0xFFFF9800)
                      : doctorant.estActif
                      ? AppTheme.primaryColor
                      : Colors.red,
                  fontSize: 14,
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
                    doctorant.nomComplet,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'INE: ${doctorant.ine ?? 'Non défini'} • ${doctorant.email}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (doctorant.ecoleDoctorale != null)
                    Text(
                      doctorant.ecoleDoctorale!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: doctorant.estEnAttente
                    ? const Color(0xFFFF9800).withOpacity(0.1)
                    : doctorant.estActif
                    ? const Color(0xFF4CAF50).withOpacity(0.1)
                    : const Color(0xFFF44336).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                doctorant.estEnAttente
                    ? 'En attente'
                    : doctorant.estActif
                    ? 'Actif'
                    : 'Inactif',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: doctorant.estEnAttente
                      ? const Color(0xFFFF9800)
                      : doctorant.estActif
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[300],
              size: 20,
            ),
          ],
        ),
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
            Icons.school_outlined,
            size: 64,
            color: AppTheme.primaryColor.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.push(AppRoutes.ajouterDoctorant),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text(
              'Ajouter un doctorant',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}