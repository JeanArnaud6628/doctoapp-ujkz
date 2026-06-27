import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/admin_service.dart';

class VueCycleDoctoral extends ConsumerStatefulWidget {
  const VueCycleDoctoral({super.key});

  @override
  ConsumerState<VueCycleDoctoral> createState() => _VueCycleDoctoralState();
}

class _VueCycleDoctoralState extends ConsumerState<VueCycleDoctoral> {
  String _filtreEtape = 'tous';
  String _recherche = '';
  String _filtreEcole = 'toutes';

  final List<String> _ecoles = ['toutes', 'EDS', 'EDLESHC', 'EDST'];

  final Map<String, Map<String, dynamic>> _etapesConfig = {
    'tous': {'label': 'Tous', 'color': AppTheme.primaryColor, 'icon': Icons.list},
    'enregistree': {'label': 'Sujet enregistré', 'color': Colors.grey, 'icon': Icons.description},
    'directeur_choisi': {'label': 'Directeur choisi ⏳', 'color': Colors.orange, 'icon': Icons.person_pin},
    'directeur_valide': {'label': 'Directeur validé', 'color': Colors.blue, 'icon': Icons.verified},
    'csi_affecte': {'label': 'CSI affecté', 'color': Colors.teal, 'icon': Icons.groups},
    'rapport_annuel_1': {'label': 'Rapport 1', 'color': Colors.orange, 'icon': Icons.assignment},
    'rapport_annuel_1_valide': {'label': 'Rapport 1 validé', 'color': Colors.green, 'icon': Icons.check_circle},
    'rapport_annuel_2': {'label': 'Rapport 2', 'color': Colors.deepOrange, 'icon': Icons.assignment},
    'rapport_annuel_2_valide': {'label': 'Rapport 2 validé', 'color': Colors.green, 'icon': Icons.check_circle},
    'rapport_annuel_3': {'label': 'Rapport 3', 'color': Colors.red, 'icon': Icons.assignment},
    'rapport_annuel_3_valide': {'label': 'Rapport 3 validé', 'color': Colors.green, 'icon': Icons.check_circle},
    'manuscrit_depose': {'label': 'Manuscrit déposé', 'color': Colors.purple, 'icon': Icons.upload_file},
    'quitus_directeur': {'label': 'Quitus Dir. ⏳', 'color': Colors.orange, 'icon': Icons.check_circle},
    'quitus_csi': {'label': 'Quitus CSI ⏳', 'color': Colors.orange, 'icon': Icons.check_circle},
    'validation_admin': {'label': 'Validation Admin ⏳', 'color': Colors.orange, 'icon': Icons.admin_panel_settings},
    'rapporteurs_affectes': {'label': 'Rapporteurs affectés', 'color': Colors.indigo, 'icon': Icons.rate_review},
    'evaluation_rapporteurs': {'label': 'Évaluation', 'color': Colors.deepPurple, 'icon': Icons.assessment},
    'soutenance_programmee': {'label': 'Soutenance programmée', 'color': Colors.green, 'icon': Icons.event},
    'soutenance_realisee': {'label': '✅ Soutenance réalisée', 'color': Colors.green, 'icon': Icons.celebration},
  };

  @override
  Widget build(BuildContext context) {
    final cycleAsync = ref.watch(cycleDoctoral);

    return Column(
      children: [
        _buildFiltres(),
        Expanded(
          child: cycleAsync.when(
            data: (cycle) {
              final filtered = _filtrerCycle(cycle);
              if (filtered.isEmpty) {
                return _EmptyState(
                  message: _recherche.isNotEmpty
                      ? 'Aucun doctorant correspondant'
                      : 'Aucun doctorant inscrit',
                );
              }
              return RefreshIndicator(
                color: AppTheme.primaryColor,
                onRefresh: () async {
                  ref.invalidate(cycleDoctoral);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _CarteCycle(
                      doctorant: filtered[index],
                      ref: ref,
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
          ),
        ),
      ],
    );
  }

  // ─── FILTRES ──────────────────────────────────────────────────────────────

  Widget _buildFiltres() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        children: [
          // Recherche
          TextField(
            onChanged: (v) => setState(() => _recherche = v),
            decoration: InputDecoration(
              hintText: 'Rechercher un doctorant...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor, size: 18),
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
          const SizedBox(height: 6),
          // Filtres étapes
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _etapesConfig.entries.map((entry) {
                final active = _filtreEtape == entry.key;
                final color = entry.value['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _filtreEtape = entry.key),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: active ? color : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: active ? color : Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          entry.value['icon'] as IconData,
                          size: 12,
                          color: active ? Colors.white : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.value['label'] as String,
                          style: TextStyle(
                            fontSize: 9,
                            color: active ? Colors.white : Colors.grey,
                            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          // Filtre école
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _ecoles.map((e) {
                final active = _filtreEcole == e;
                return GestureDetector(
                  onTap: () => setState(() => _filtreEcole = e),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primaryColor : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? AppTheme.primaryColor : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      e == 'toutes' ? 'Toutes' : e,
                      style: TextStyle(
                        fontSize: 9,
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

  List<Map<String, dynamic>> _filtrerCycle(List<Map<String, dynamic>> cycle) {
    var filtered = cycle;

    if (_filtreEcole != 'toutes') {
      filtered = filtered.where((d) {
        final ecole = d['ecole_doctorale'] as String? ?? '';
        return ecole == _filtreEcole;
      }).toList();
    }

    if (_filtreEtape != 'tous') {
      filtered = filtered.where((d) {
        final theses = d['theses'] as List?;
        if (theses == null || theses.isEmpty) return false;
        final these = theses[0] as Map<String, dynamic>;
        return these['etape_actuelle'] == _filtreEtape;
      }).toList();
    }

    if (_recherche.isNotEmpty) {
      final q = _recherche.toLowerCase();
      filtered = filtered.where((d) {
        final nom = (d['nom'] as String? ?? '').toLowerCase();
        final prenom = (d['prenom'] as String? ?? '').toLowerCase();
        final ine = (d['ine'] as String? ?? '').toLowerCase();
        return nom.contains(q) || prenom.contains(q) || ine.contains(q);
      }).toList();
    }

    return filtered;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CARTE CYCLE
// ═══════════════════════════════════════════════════════════════════════════

class _CarteCycle extends StatelessWidget {
  final Map<String, dynamic> doctorant;
  final WidgetRef ref;

  const _CarteCycle({
    required this.doctorant,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theses = doctorant['theses'] as List?;
    final these = (theses != null && theses.isNotEmpty)
        ? theses[0] as Map<String, dynamic>
        : null;

    final etape = these?['etape_actuelle'] as String? ?? 'enregistree';
    final annee = these?['annee_en_cours'] as int? ?? 1;
    final quitusDir = these?['quitus_directeur'] as bool? ?? false;
    final quitusCsi = these?['quitus_csi'] as bool? ?? false;
    final validationAdmin = these?['validation_admin'] as bool? ?? false;

    final progression = _getProgression(etape);
    final etapeConfig = _etapeConfig(etape);

    final nom = '${doctorant['prenom'] ?? ''} ${doctorant['nom'] ?? ''}';
    final ine = doctorant['ine'] as String? ?? '';
    final ecole = doctorant['ecole_doctorale'] as String? ?? '';

    // Vérifier si le directeur est en attente
    final directeurEnAttente = etape == 'directeur_choisi';

    return GestureDetector(
      onTap: () => context.push(
        '${AppRoutes.profilDoctorantAdmin}/${doctorant['id']}',
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: directeurEnAttente
                ? Colors.orange
                : etapeConfig['color'].withOpacity(0.3),
            width: directeurEnAttente ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (directeurEnAttente ? Colors.orange : etapeConfig['color']).withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── En-tête ──────────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: etapeConfig['color'].withOpacity(0.15),
                  radius: 20,
                  child: Text(
                    nom.isNotEmpty ? nom[0].toUpperCase() : 'D',
                    style: TextStyle(
                      color: etapeConfig['color'],
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$ine · $ecole',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: etapeConfig['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'An. $annee',
                        style: TextStyle(
                          fontSize: 9,
                          color: etapeConfig['color'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(progression * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: etapeConfig['color'],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ─── Titre thèse ─────────────────────────────────────────────
            if (these != null)
              Text(
                these['titre'] as String? ?? 'Thèse enregistrée',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textGray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),

            // ─── Indicateur directeur en attente ─────────────────────────
            if (directeurEnAttente)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pending, color: Colors.orange, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '⏳ En attente validation directeur',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if (directeurEnAttente) const SizedBox(height: 8),

            // ─── Barre de progression ────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progression,
                backgroundColor: Colors.grey[100],
                valueColor: AlwaysStoppedAnimation<Color>(etapeConfig['color']),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),

            // ─── Étape et indicateurs ────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: etapeConfig['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        etapeConfig['icon'],
                        size: 10,
                        color: etapeConfig['color'],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        etapeConfig['label'],
                        style: TextStyle(
                          fontSize: 9,
                          color: etapeConfig['color'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (these != null) ...[
                  _IndicateurMini('Dir.', quitusDir, Colors.blue),
                  const SizedBox(width: 6),
                  _IndicateurMini('CSI', quitusCsi, Colors.teal),
                  const SizedBox(width: 6),
                  _IndicateurMini('Admin', validationAdmin, AppTheme.primaryColor),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Configuration étape ──────────────────────────────────────────────────

  Map<String, dynamic> _etapeConfig(String etape) {
    const configs = {
      'enregistree': {'label': 'Sujet enregistré', 'color': Colors.grey, 'icon': Icons.description},
      'directeur_choisi': {'label': 'Directeur choisi ⏳', 'color': Colors.orange, 'icon': Icons.person_pin},
      'directeur_valide': {'label': 'Directeur validé', 'color': Colors.blue, 'icon': Icons.verified},
      'csi_affecte': {'label': 'CSI affecté', 'color': Colors.teal, 'icon': Icons.groups},
      'rapport_annuel_1': {'label': 'Rapport 1', 'color': Colors.orange, 'icon': Icons.assignment},
      'rapport_annuel_1_valide': {'label': 'Rapport 1 validé', 'color': Colors.green, 'icon': Icons.check_circle},
      'rapport_annuel_2': {'label': 'Rapport 2', 'color': Colors.deepOrange, 'icon': Icons.assignment},
      'rapport_annuel_2_valide': {'label': 'Rapport 2 validé', 'color': Colors.green, 'icon': Icons.check_circle},
      'rapport_annuel_3': {'label': 'Rapport 3', 'color': Colors.red, 'icon': Icons.assignment},
      'rapport_annuel_3_valide': {'label': 'Rapport 3 validé', 'color': Colors.green, 'icon': Icons.check_circle},
      'manuscrit_depose': {'label': 'Manuscrit déposé', 'color': Colors.purple, 'icon': Icons.upload_file},
      'quitus_directeur': {'label': 'Quitus Dir. ⏳', 'color': Colors.orange, 'icon': Icons.check_circle},
      'quitus_csi': {'label': 'Quitus CSI ⏳', 'color': Colors.orange, 'icon': Icons.check_circle},
      'validation_admin': {'label': 'Validation Admin ⏳', 'color': Colors.orange, 'icon': Icons.admin_panel_settings},
      'rapporteurs_affectes': {'label': 'Rapporteurs affectés', 'color': Colors.indigo, 'icon': Icons.rate_review},
      'evaluation_rapporteurs': {'label': 'Évaluation', 'color': Colors.deepPurple, 'icon': Icons.assessment},
      'soutenance_programmee': {'label': 'Soutenance programmée', 'color': Colors.green, 'icon': Icons.event},
      'soutenance_realisee': {'label': '✅ Soutenance réalisée', 'color': Colors.green, 'icon': Icons.celebration},
    };
    return configs[etape] ?? configs['enregistree']!;
  }

  // ─── Progression ──────────────────────────────────────────────────────────

  double _getProgression(String etape) {
    const etapes = {
      'enregistree': 0.05,
      'directeur_choisi': 0.10,
      'directeur_valide': 0.15,
      'csi_affecte': 0.20,
      'rapport_annuel_1': 0.30,
      'rapport_annuel_1_valide': 0.35,
      'rapport_annuel_2': 0.45,
      'rapport_annuel_2_valide': 0.50,
      'rapport_annuel_3': 0.60,
      'rapport_annuel_3_valide': 0.65,
      'manuscrit_depose': 0.70,
      'quitus_directeur': 0.75,
      'quitus_csi': 0.80,
      'validation_admin': 0.85,
      'rapporteurs_affectes': 0.90,
      'evaluation_rapporteurs': 0.92,
      'soutenance_programmee': 0.95,
      'soutenance_realisee': 1.0,
    };
    return etapes[etape] ?? 0.05;
  }
}

// ─── INDICATEUR MINI ───────────────────────────────────────────────────────

class _IndicateurMini extends StatelessWidget {
  final String label;
  final bool valide;
  final Color color;

  const _IndicateurMini(this.label, this.valide, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          valide ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 12,
          color: valide ? color : Colors.grey,
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: valide ? color : Colors.grey,
          ),
        ),
      ],
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