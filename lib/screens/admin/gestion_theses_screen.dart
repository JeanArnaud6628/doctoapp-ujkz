import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../models/these_model.dart';
import '../../models/utilisateur_model.dart';

class GestionThesesScreen extends ConsumerStatefulWidget {
  const GestionThesesScreen({super.key});

  @override
  ConsumerState<GestionThesesScreen> createState() =>
      _GestionThesesScreenState();
}

class _GestionThesesScreenState extends ConsumerState<GestionThesesScreen> {
  String _filtreEtape = 'tous';
  String _recherche = '';

  final Map<String, Map<String, dynamic>> _etapesConfig = {
    'tous': {'label': 'Tous', 'color': AppTheme.primaryColor},
    'enregistree': {'label': 'Enregistrée', 'color': Colors.grey},
    'en_cours': {'label': 'En cours', 'color': Colors.blue},
    'en_instruction': {'label': 'En instruction', 'color': Colors.purple},
    'soutenue': {'label': 'Soutenue', 'color': Colors.green},
    'abandonnee': {'label': 'Abandonnée', 'color': Colors.red},
  };

  @override
  Widget build(BuildContext context) {
    final thesesAsync = ref.watch(thesesAdminProvider);
    final doctorantsAsync = ref.watch(doctorantsProvider);
    final directeursAsync = ref.watch(directeursAdminProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des Thèses'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildFiltres(),
        ),
      ),
      body: thesesAsync.when(
        data: (theses) {
          final filtered = _filtrerTheses(theses);
          if (filtered.isEmpty) {
            return _EmptyState(
              message: _recherche.isNotEmpty
                  ? 'Aucune thèse correspondant à la recherche'
                  : 'Aucune thèse enregistrée',
            );
          }
          return RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async {
              ref.invalidate(thesesAdminProvider);
              ref.invalidate(doctorantsProvider);
              ref.invalidate(directeursAdminProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final t = filtered[index];

                final doctorant = doctorantsAsync.asData?.value
                    .firstWhere((d) => d.id == t.doctorantId,
                    orElse: () => UtilisateurModel(
                      id: '',
                      nom: 'Inconnu',
                      prenom: '',
                      email: '',
                      role: 'doctorant',
                    ));
                final directeur = directeursAsync.asData?.value
                    .firstWhere((d) => d.id == t.directeurId,
                    orElse: () => UtilisateurModel(
                      id: '',
                      nom: 'Non assigné',
                      prenom: '',
                      email: '',
                      role: 'directeur',
                    ));

                return _TheseCard(
                  these: t,
                  doctorant: doctorant,
                  directeur: directeur,
                  onTap: () {
                    if (t.doctorantId.isNotEmpty) {
                      context.push(
                        '${AppRoutes.profilDoctorantAdmin}/${t.doctorantId}',
                      );
                    }
                  },
                  onEtatChange: (nouvelEtat) async {
                    await ref
                        .read(adminServiceProvider)
                        .updateEtatThese(t.id, nouvelEtat);
                    ref.invalidate(thesesAdminProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('État mis à jour : ${_getEtatLibelle(nouvelEtat)}'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    }
                  },
                  onValiderDirecteur: () async {
                    await ref
                        .read(adminServiceProvider)
                        .updateEtapeThese(t.id, 'directeur_valide');
                    ref.invalidate(thesesAdminProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Directeur validé !'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    }
                  },
                  onValiderManuscrit: () async {
                    await ref
                        .read(adminServiceProvider)
                        .updateEtapeThese(t.id, 'validation_admin');
                    ref.invalidate(thesesAdminProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Manuscrit validé !'),
                          backgroundColor: AppTheme.primaryColor,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TextField(
              onChanged: (value) => setState(() => _recherche = value),
              decoration: InputDecoration(
                hintText: 'Rechercher une thèse...',
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: _etapesConfig.entries.map((entry) {
                final active = _filtreEtape == entry.key;
                final color = entry.value['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _filtreEtape = entry.key),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: active ? color : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: active ? color : Colors.grey[300]!),
                    ),
                    child: Text(
                      entry.value['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: active ? Colors.white : Colors.grey,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<TheseModel> _filtrerTheses(List<TheseModel> theses) {
    var filtered = theses;

    if (_filtreEtape != 'tous') {
      filtered = filtered.where((t) => t.etat == _filtreEtape).toList();
    }

    if (_recherche.isNotEmpty) {
      final q = _recherche.toLowerCase();
      filtered = filtered.where((t) {
        return t.titre.toLowerCase().contains(q) ||
            (t.specialite?.toLowerCase().contains(q) ?? false) ||
            (t.motsCles?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return filtered;
  }

  String _getEtatLibelle(String etat) {
    switch (etat) {
      case 'enregistree': return 'Enregistrée';
      case 'en_cours': return 'En cours';
      case 'en_instruction': return 'En instruction';
      case 'soutenue': return 'Soutenue';
      case 'abandonnee': return 'Abandonnée';
      default: return etat;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CARTE THÈSE
// ═══════════════════════════════════════════════════════════════════════════

class _TheseCard extends StatelessWidget {
  final TheseModel these;
  final UtilisateurModel? doctorant;
  final UtilisateurModel? directeur;
  final VoidCallback onTap;
  final Function(String) onEtatChange;
  final VoidCallback onValiderDirecteur;
  final VoidCallback onValiderManuscrit;

  const _TheseCard({
    required this.these,
    required this.doctorant,
    required this.directeur,
    required this.onTap,
    required this.onEtatChange,
    required this.onValiderDirecteur,
    required this.onValiderManuscrit,
  });

  @override
  Widget build(BuildContext context) {
    Color etatColor;
    switch (these.etat) {
      case 'enregistree':
        etatColor = Colors.grey;
        break;
      case 'en_cours':
        etatColor = Colors.blue;
        break;
      case 'en_instruction':
        etatColor = Colors.purple;
        break;
      case 'soutenue':
        etatColor = Colors.green;
        break;
      case 'abandonnee':
        etatColor = Colors.red;
        break;
      default:
        etatColor = AppTheme.textGray;
    }

    final doctorantNom = doctorant != null
        ? '${doctorant!.prenom} ${doctorant!.nom}'
        : 'Inconnu';
    final directeurNom = directeur != null && directeur!.nom != 'Non assigné'
        ? '${directeur!.prenom} ${directeur!.nom}'
        : 'Non assigné';

    final quitusDir = these.quitusDirecteur ?? false;
    final quitusCsi = these.quitusCsi ?? false;
    final validationAdmin = these.validationAdmin ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE8DD), width: 0.5),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: etatColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    these.etatLibelle,
                    style: TextStyle(color: etatColor, fontSize: 10),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: onEtatChange,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'en_cours',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow, color: Colors.blue, size: 16),
                          SizedBox(width: 8),
                          Text('Passer en cours'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'en_instruction',
                      child: Row(
                        children: [
                          Icon(Icons.school, color: Colors.purple, size: 16),
                          SizedBox(width: 8),
                          Text('Passer en instruction'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'soutenue',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text('Marquer soutenue'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'abandonnee',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('Abandonner'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              these.titre,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (these.specialite != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  these.specialite!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGray,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _InfoTag(
                    icon: Icons.person,
                    label: doctorantNom,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoTag(
                    icon: Icons.person_pin,
                    label: directeurNom,
                    color: const Color(0xFF0D47A1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (these.motsCles != null && these.motsCles!.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: these.motsCles!.split(',').take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag.trim(),
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
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
                const SizedBox(width: 6),
                _QuitusChip(
                  label: 'Validation Admin',
                  ok: validationAdmin,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: these.progression / 100,
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor: AlwaysStoppedAnimation<Color>(etatColor),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progression',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${these.progression}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: etatColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

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
            Icons.description_outlined,
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