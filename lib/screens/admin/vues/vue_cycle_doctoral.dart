import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/admin_provider.dart';

class VueCycleDoctoral extends ConsumerStatefulWidget {
  const VueCycleDoctoral({super.key});

  @override
  ConsumerState<VueCycleDoctoral> createState() =>
      _VueCycleDoctoralState();
}

class _VueCycleDoctoralState extends ConsumerState<VueCycleDoctoral> {
  String _filtreEtape = 'tous';
  String _recherche = '';

  final Map<String, Map<String, dynamic>> _etapesConfig = {
    'tous': {'label': 'Tous', 'color': AppTheme.primaryColor},
    'enregistree': {'label': 'Enregistré', 'color': Colors.grey},
    'directeur_choisi': {'label': 'Directeur', 'color': Colors.blue},
    'csi_affecte': {'label': 'CSI', 'color': Colors.teal},
    'rapport_annuel_1': {'label': 'Rapport 1', 'color': Colors.orange},
    'rapport_annuel_2': {'label': 'Rapport 2', 'color': Colors.deepOrange},
    'rapport_annuel_3': {'label': 'Rapport 3', 'color': Colors.red},
    'manuscrit_depose': {'label': 'Manuscrit', 'color': Colors.purple},
    'rapporteurs_affectes': {'label': 'Rapporteurs', 'color': Colors.indigo},
    'soutenance_programmee': {'label': 'Soutenance', 'color': Colors.green},
  };

  @override
  Widget build(BuildContext context, ) {
    final cycleAsync = ref.watch(cycleDoctoral);

    return Column(
      children: [
        // Filtres par étape
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _etapesConfig.entries.map((entry) {
                final active = _filtreEtape == entry.key;
                final color = entry.value['color'] as Color;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _filtreEtape = entry.key),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? color : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                          active ? color : Colors.grey[300]!),
                    ),
                    child: Text(entry.value['label'] as String,
                        style: TextStyle(
                            fontSize: 11,
                            color:
                            active ? Colors.white : Colors.grey,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Recherche
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            onChanged: (v) => setState(() => _recherche = v),
            decoration: InputDecoration(
              hintText: 'Rechercher un doctorant...',
              prefixIcon: const Icon(Icons.search,
                  color: AppTheme.primaryColor, size: 18),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              filled: true,
              fillColor: const Color(0xFFF8FBF8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFFC8DFC8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFFC8DFC8)),
              ),
            ),
          ),
        ),
        // Liste doctorants avec cycle
        Expanded(
          child: cycleAsync.when(
            data: (cycle) {
              var filtered = cycle;

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

              if (filtered.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined,
                          size: 48, color: AppTheme.primaryColor),
                      SizedBox(height: 12),
                      Text('Aucun doctorant trouvé',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textGray)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppTheme.primaryColor,
                onRefresh: () async => ref.invalidate(cycleDoctoral),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _CarteCycle(
                        doctorant: filtered[index]);
                  },
                ),
              );
            },
            loading: () => const Center(
                child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Erreur: $e')),
          ),
        ),
      ],
    );
  }
}

class _CarteCycle extends StatelessWidget {
  final Map<String, dynamic> doctorant;
  const _CarteCycle({required this.doctorant});

  @override
  Widget build(BuildContext context) {
    final theses = doctorant['theses'] as List?;
    final these = (theses != null && theses.isNotEmpty)
        ? theses[0] as Map<String, dynamic>
        : null;

    final etape = these?['etape_actuelle'] as String? ?? 'enregistree';
    final etat = these?['etat'] as String? ?? '';
    final annee = these?['annee_en_cours'] as int? ?? 1;
    final quitusDir = these?['quitus_directeur'] as bool? ?? false;
    final quitusCsi = these?['quitus_csi'] as bool? ?? false;

    // Calculer progression
    const etapesProg = {
      'enregistree': 0.05,
      'directeur_choisi': 0.15,
      'directeur_valide': 0.20,
      'csi_affecte': 0.25,
      'rapport_annuel_1': 0.35,
      'rapport_annuel_2': 0.50,
      'rapport_annuel_3': 0.65,
      'manuscrit_depose': 0.70,
      'quitus_directeur': 0.75,
      'quitus_csi': 0.80,
      'rapporteurs_affectes': 0.85,
      'evaluation_rapporteurs': 0.90,
      'soutenance_programmee': 0.95,
      'soutenance_realisee': 1.0,
    };
    final prog = etapesProg[etape] ?? 0.05;

    Color etapeColor;
    if (prog >= 0.90) etapeColor = Colors.green;
    else if (prog >= 0.65) etapeColor = Colors.blue;
    else if (prog >= 0.35) etapeColor = Colors.orange;
    else etapeColor = Colors.grey;

    final nom = '${doctorant['prenom'] ?? ''} ${doctorant['nom'] ?? ''}';
    final ine = doctorant['ine'] as String? ?? '';
    final ecole = doctorant['ecole_doctorale'] as String? ?? '';

    return GestureDetector(
      onTap: () => context.push(
          '${AppRoutes.profilDoctorantAdmin}/${doctorant['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: etapeColor.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: etapeColor,
                  radius: 22,
                  child: Text(
                    nom.isNotEmpty ? nom[0].toUpperCase() : 'D',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nom,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text('$ine · $ecole',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textGray)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: etapeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'An. $annee',
                        style: TextStyle(
                            fontSize: 10,
                            color: etapeColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${(prog * 100).round()}%',
                        style: TextStyle(
                            fontSize: 12,
                            color: etapeColor,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Titre thèse
            if (these != null)
              Text(
                these['titre'] as String? ?? 'Thèse enregistrée',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textGray),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: prog,
                backgroundColor: Colors.grey[100],
                valueColor: AlwaysStoppedAnimation<Color>(etapeColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            // Étape actuelle
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: etapeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _etapeLibelle(etape),
                    style: TextStyle(
                        fontSize: 10,
                        color: etapeColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                // Indicateurs quitus
                if (these != null) ...[
                  _IndicateurMini(
                      'Dir.', quitusDir, Colors.blue),
                  const SizedBox(width: 4),
                  _IndicateurMini('CSI', quitusCsi, Colors.teal),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _etapeLibelle(String etape) {
    const map = {
      'enregistree': 'Sujet enregistré',
      'directeur_choisi': 'Directeur choisi',
      'directeur_valide': 'Directeur validé',
      'csi_affecte': 'CSI affecté',
      'rapport_annuel_1': 'Rapport An. 1',
      'rapport_annuel_2': 'Rapport An. 2',
      'rapport_annuel_3': 'Rapport An. 3',
      'manuscrit_depose': 'Manuscrit déposé',
      'quitus_directeur': 'Quitus Directeur',
      'quitus_csi': 'Quitus CSI',
      'rapporteurs_affectes': 'Rapporteurs affectés',
      'evaluation_rapporteurs': 'Évaluation en cours',
      'soutenance_programmee': 'Soutenance programmée',
      'soutenance_realisee': 'Soutenance réalisée',
    };
    return map[etape] ?? etape;
  }
}

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
        Text(label,
            style: TextStyle(
                fontSize: 9,
                color: valide ? color : Colors.grey)),
      ],
    );
  }
}