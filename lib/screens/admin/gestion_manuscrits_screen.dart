import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../models/these_model.dart';
import '../../models/utilisateur_model.dart';

class GestionManuscritsScreen extends ConsumerStatefulWidget {
  const GestionManuscritsScreen({super.key});

  @override
  ConsumerState<GestionManuscritsScreen> createState() =>
      _GestionManuscritsScreenState();
}

class _GestionManuscritsScreenState
    extends ConsumerState<GestionManuscritsScreen> {
  String _filtreStatut = 'tous';
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    final manuscritsAsync = ref.watch(tousManuscritsProvider);
    final doctorantsAsync = ref.watch(doctorantsProvider);
    final thesesAsync = ref.watch(thesesAdminProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des Manuscrits'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildFiltres(),
        ),
      ),
      body: manuscritsAsync.when(
        data: (manuscrits) {
          final filtered = _filtrerManuscrits(manuscrits);
          if (filtered.isEmpty) {
            return _EmptyState(
              message: _recherche.isNotEmpty
                  ? 'Aucun manuscrit correspondant'
                  : 'Aucun manuscrit trouvé',
            );
          }
          return RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async {
              ref.invalidate(tousManuscritsProvider);
              ref.invalidate(manuscritsEnAttenteProvider);
              ref.invalidate(doctorantsProvider);
              ref.invalidate(thesesAdminProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final m = filtered[index];

                final these = thesesAsync.asData?.value
                    .firstWhere(
                      (t) => t.id == m['these_id'],
                  orElse: () => TheseModel(
                    id: '',
                    titre: 'Sans thèse',
                    doctorantId: '',
                  ),
                ) ??
                    TheseModel(
                      id: '',
                      titre: 'Sans thèse',
                      doctorantId: '',
                    );

                final doctorant = doctorantsAsync.asData?.value
                    .firstWhere(
                      (d) => d.id == these.doctorantId,
                  orElse: () => UtilisateurModel(
                    id: '',
                    nom: 'Inconnu',
                    prenom: '',
                    email: '',
                    role: 'doctorant',
                  ),
                ) ??
                    UtilisateurModel(
                      id: '',
                      nom: 'Inconnu',
                      prenom: '',
                      email: '',
                      role: 'doctorant',
                    );

                return _ManuscritCard(
                  manuscrit: m,
                  these: these,
                  doctorant: doctorant,
                  onValider: () async {
                    // 🔧 VÉRIFIER LES QUITUS AVANT VALIDATION
                    final quitusDir = these.quitusDirecteur ?? false;
                    final quitusCsi = these.quitusCsi ?? false;

                    if (!quitusDir || !quitusCsi) {
                      if (context.mounted) {
                        _showQuitusDialog(context, quitusDir, quitusCsi);
                      }
                      return;
                    }

                    await ref
                        .read(adminServiceProvider)
                        .validerManuscrit(m['id'], m['these_id'] ?? '');
                    ref.invalidate(tousManuscritsProvider);
                    ref.invalidate(manuscritsEnAttenteProvider);
                    ref.invalidate(thesesAdminProvider);
                    ref.invalidate(adminStatsProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Manuscrit validé !'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    }
                  },
                  onRejeter: () async {
                    await ref
                        .read(adminServiceProvider)
                        .rejeterManuscrit(m['id']);
                    ref.invalidate(tousManuscritsProvider);
                    ref.invalidate(manuscritsEnAttenteProvider);
                    ref.invalidate(adminStatsProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ Manuscrit rejeté'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  // ─── FILTRES ──────────────────────────────────────────────────────────────

  Widget _buildFiltres() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: TextField(
              onChanged: (value) => setState(() => _recherche = value),
              decoration: InputDecoration(
                hintText: 'Rechercher un manuscrit...',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: const Color(0xFFF8FBF8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFC8DFC8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFC8DFC8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                ),
                isDense: true,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                _buildFilterChip('Tous', 'tous'),
                _buildFilterChip('En attente', 'en attente'),
                _buildFilterChip('Validés', 'valide'),
                _buildFilterChip('Rejetés', 'rejete'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtreStatut == value;
    return GestureDetector(
      onTap: () => setState(() => _filtreStatut = value),
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

  List<Map<String, dynamic>> _filtrerManuscrits(
      List<Map<String, dynamic>> manuscrits) {
    var filtered = manuscrits;
    if (_filtreStatut != 'tous') {
      filtered = filtered.where((m) => m['statut'] == _filtreStatut).toList();
    }
    if (_recherche.isNotEmpty) {
      final q = _recherche.toLowerCase();
      filtered = filtered.where((m) {
        final titre = (m['titre'] as String? ?? '').toLowerCase();
        return titre.contains(q);
      }).toList();
    }
    return filtered;
  }

  // ─── DIALOGUE QUITUS ──────────────────────────────────────────────────────

  void _showQuitusDialog(BuildContext context, bool quitusDir, bool quitusCsi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('❌ Validation impossible'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Les quitus suivants sont manquants :',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            if (!quitusDir)
              const Row(
                children: [
                  Icon(Icons.close, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text('Quitus Directeur non obtenu'),
                ],
              ),
            if (!quitusCsi)
              const Row(
                children: [
                  Icon(Icons.close, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text('Quitus CSI non obtenu'),
                ],
              ),
            const SizedBox(height: 12),
            const Text(
              'Veuillez d\'abord valider les quitus avant de valider le manuscrit.',
              style: TextStyle(fontSize: 12, color: AppTheme.textGray),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CARTE MANUSCRIT
// ═══════════════════════════════════════════════════════════════════════════

class _ManuscritCard extends StatelessWidget {
  final Map<String, dynamic> manuscrit;
  final TheseModel these;
  final UtilisateurModel doctorant;
  final VoidCallback onValider;
  final VoidCallback onRejeter;

  const _ManuscritCard({
    required this.manuscrit,
    required this.these,
    required this.doctorant,
    required this.onValider,
    required this.onRejeter,
  });

  @override
  Widget build(BuildContext context) {
    final isEnAttente = manuscrit['statut'] == 'en attente';
    final isValide = manuscrit['statut'] == 'valide';
    final isRejete = manuscrit['statut'] == 'rejete';

    final quitusDir = these.quitusDirecteur ?? false;
    final quitusCsi = these.quitusCsi ?? false;
    final quitusOk = quitusDir && quitusCsi;

    Color statutColor;
    String statutLabel;
    Color statutBg;

    if (isValide) {
      statutColor = Colors.green;
      statutLabel = 'Validé ✅';
      statutBg = const Color(0xFFE8F5E9);
    } else if (isRejete) {
      statutColor = Colors.red;
      statutLabel = 'Rejeté ❌';
      statutBg = const Color(0xFFFFEBEE);
    } else {
      statutColor = quitusOk ? const Color(0xFFE65100) : Colors.grey;
      statutLabel = quitusOk ? 'En attente ⏳' : '⚠️ Quitus manquants';
      statutBg = quitusOk ? const Color(0xFFFFF3E0) : const Color(0xFFF5F5F5);
    }

    final doctorantNom = doctorant.nom != 'Inconnu'
        ? '${doctorant.prenom} ${doctorant.nom}'
        : 'Inconnu';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEnAttente
              ? (quitusOk ? const Color(0xFFFFE0A0) : Colors.grey[300]!)
              : const Color(0xFFDDE8DD),
          width: isEnAttente && quitusOk ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isEnAttente && quitusOk
                ? const Color(0xFFFFE0A0).withOpacity(0.3)
                : Colors.black.withOpacity(0.03),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isEnAttente
                      ? (quitusOk
                      ? const Color(0xFFFFF3E0)
                      : const Color(0xFFF5F5F5))
                      : isValide
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEnAttente
                      ? (quitusOk ? Icons.upload_file : Icons.block)
                      : isValide
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: isEnAttente
                      ? (quitusOk ? const Color(0xFFE65100) : Colors.grey)
                      : isValide
                      ? Colors.green
                      : Colors.red,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manuscrit['titre'] ?? 'Sans titre',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isEnAttente && !quitusOk
                            ? Colors.grey
                            : AppTheme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Déposé le ${manuscrit['date_depot'] ?? '–'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statutBg,
                  borderRadius: BorderRadius.circular(10),
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
          const SizedBox(height: 10),

          // ─── Doctorant ──────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: AppTheme.textGray),
              const SizedBox(width: 4),
              Text(
                'Doctorant : $doctorantNom',
                style: TextStyle(
                  fontSize: 11,
                  color: isEnAttente && !quitusOk ? Colors.grey : AppTheme.textGray,
                ),
              ),
            ],
          ),
          if (these.titre.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.description, size: 14, color: AppTheme.textGray),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Thèse : ${these.titre}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isEnAttente && !quitusOk ? Colors.grey : AppTheme.textGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),

          // ─── Indicateurs quitus ────────────────────────────────────────
          if (isEnAttente) ...[
            Row(
              children: [
                _QuitusChip(
                  label: 'Quitus Dir.',
                  ok: quitusDir,
                  color: Colors.blue,
                ),
                const SizedBox(width: 6),
                _QuitusChip(
                  label: 'Quitus CSI',
                  ok: quitusCsi,
                  color: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // ─── Actions ────────────────────────────────────────────────────
          if (isEnAttente) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRejeter,
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    label: const Text(
                      'Rejeter',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: quitusOk ? onValider : null,
                    icon: Icon(
                      quitusOk ? Icons.check : Icons.block,
                      size: 16,
                    ),
                    label: Text(
                      quitusOk ? 'Valider' : 'Quitus manquants',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: quitusOk
                          ? AppTheme.primaryColor
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ─── Message final ─────────────────────────────────────────────
          if (!isEnAttente)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statutBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isValide ? Icons.check_circle : Icons.cancel,
                    color: statutColor,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isValide
                        ? 'Manuscrit validé par l\'administration'
                        : 'Manuscrit rejeté',
                    style: TextStyle(
                      fontSize: 11,
                      color: statutColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _QuitusChip extends StatelessWidget {
  final String label;
  final bool ok;
  final Color color;

  const _QuitusChip({
    required this.label,
    required this.ok,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ok ? color.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ok ? color : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 10,
            color: ok ? color : Colors.grey,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: ok ? color : Colors.grey,
              fontWeight: ok ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

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
            Icons.upload_file_outlined,
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