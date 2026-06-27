import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/utilisateur_model.dart';

class VueGestion extends ConsumerWidget {
  const VueGestion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directeursAsync = ref.watch(directeursAvecStats);
    final csiAsync = ref.watch(csiAvecStats);
    final rapporteursAsync = ref.watch(rapporteursAvecStats);
    final doctorantsAsync = ref.watch(doctorantsProvider);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ─── DOCTORANTS ──────────────────────────────────────────────────
        _SectionGestion(
          titre: 'DOCTORANTS',
          couleur: AppTheme.primaryColor,
          icone: Icons.school_rounded,
          routeAjouter: AppRoutes.ajouterDoctorant,
          routeVoirTout: AppRoutes.gestionDoctorants,
          contenu: doctorantsAsync.when(
            data: (doctorants) {
              final recent = doctorants.take(3).toList();
              if (recent.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aucun doctorant'),
                  ),
                );
              }
              return Column(
                children: recent.map((d) {
                  return _CarteUtilisateur(
                    nom: d.nomComplet,
                    info1: 'INE: ${d.ine ?? 'Non défini'}',
                    info2: d.ecoleDoctorale ?? '–',
                    actif: d.actif,
                    couleur: AppTheme.primaryColor,
                    onTap: () => context.push(
                      '${AppRoutes.profilDoctorantAdmin}/${d.id}',
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
        ),
        const SizedBox(height: 14),

        // ─── DIRECTEURS ──────────────────────────────────────────────────
        _SectionGestion(
          titre: 'DIRECTEURS DE THÈSE',
          couleur: const Color(0xFF0D47A1),
          icone: Icons.person_pin_rounded,
          routeAjouter: AppRoutes.ajouterDirecteur,
          routeVoirTout: AppRoutes.gestionDirecteurs,
          contenu: directeursAsync.when(
            data: (dirs) {
              final recent = dirs.take(3).toList();
              if (recent.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aucun directeur'),
                  ),
                );
              }
              return Column(
                children: recent.map((d) {
                  return _CarteUtilisateur(
                    nom: '${d['prenom'] ?? ''} ${d['nom'] ?? ''}',
                    info1: '${d['nb_doctorants'] ?? 0} doctorant(s)',
                    info2: d['ecole_doctorale'] as String? ?? '–',
                    actif: d['actif'] as bool? ?? true,
                    couleur: const Color(0xFF0D47A1),
                    onTap: () {},
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
        ),
        const SizedBox(height: 14),

        // ─── CSI ─────────────────────────────────────────────────────────
        _SectionGestion(
          titre: 'MEMBRES CSI',
          couleur: const Color(0xFF00695C),
          icone: Icons.groups_rounded,
          routeAjouter: AppRoutes.ajouterCSI,
          routeVoirTout: AppRoutes.gestionCSI,
          contenu: csiAsync.when(
            data: (csiList) {
              final recent = csiList.take(3).toList();
              if (recent.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aucun membre CSI'),
                  ),
                );
              }
              return Column(
                children: recent.map((c) {
                  return _CarteUtilisateur(
                    nom: '${c['prenom'] ?? ''} ${c['nom'] ?? ''}',
                    info1: '${c['nb_doctorants'] ?? 0} doctorant(s) suivis',
                    info2: c['ecole_doctorale'] as String? ?? '–',
                    actif: c['actif'] as bool? ?? true,
                    couleur: const Color(0xFF00695C),
                    onTap: () {},
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
        ),
        const SizedBox(height: 14),

        // ─── RAPPORTEURS ─────────────────────────────────────────────────
        _SectionGestion(
          titre: 'RAPPORTEURS',
          couleur: const Color(0xFF6A1B9A),
          icone: Icons.rate_review_rounded,
          routeAjouter: AppRoutes.ajouterRapporteur,
          routeVoirTout: AppRoutes.gestionRapporteurs,
          contenu: rapporteursAsync.when(
            data: (raps) {
              final recent = raps.take(3).toList();
              if (recent.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aucun rapporteur'),
                  ),
                );
              }
              return Column(
                children: recent.map((r) {
                  final libre = r['est_libre'] as bool? ?? true;
                  return _CarteUtilisateur(
                    nom: '${r['prenom'] ?? ''} ${r['nom'] ?? ''}',
                    info1: '${r['nb_en_cours'] ?? 0} en cours · ${r['nb_termines'] ?? 0} terminés',
                    info2: r['domaines_expertise'] as String? ?? r['specialite'] as String? ?? '–',
                    actif: r['actif'] as bool? ?? true,
                    couleur: const Color(0xFF6A1B9A),
                    badgeLibre: libre,
                    onTap: () {},
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION GESTION
// ═══════════════════════════════════════════════════════════════════════════

class _SectionGestion extends StatelessWidget {
  final String titre;
  final Color couleur;
  final IconData icone;
  final String routeAjouter;
  final String routeVoirTout;
  final Widget contenu;

  const _SectionGestion({
    required this.titre,
    required this.couleur,
    required this.icone,
    required this.routeAjouter,
    required this.routeVoirTout,
    required this.contenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: couleur.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: couleur.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icone, color: couleur, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  titre,
                  style: TextStyle(
                    fontSize: 12,
                    color: couleur,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push(routeVoirTout),
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(fontSize: 11, color: AppTheme.primaryColor),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(routeAjouter),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: couleur,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: contenu,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CARTE UTILISATEUR
// ═══════════════════════════════════════════════════════════════════════════

class _CarteUtilisateur extends StatelessWidget {
  final String nom;
  final String info1;
  final String info2;
  final bool actif;
  final Color couleur;
  final bool badgeLibre;
  final VoidCallback onTap;

  const _CarteUtilisateur({
    required this.nom,
    required this.info1,
    required this.info2,
    required this.actif,
    required this.couleur,
    this.badgeLibre = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBF8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFE8EEE8),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: couleur.withOpacity(0.15),
              radius: 18,
              child: Text(
                nom.isNotEmpty ? nom[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: couleur,
                  fontWeight: FontWeight.bold,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    info1,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textGray,
                    ),
                  ),
                  Text(
                    info2,
                    style: TextStyle(
                      fontSize: 9,
                      color: couleur.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: actif
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    actif ? 'Actif' : 'Inactif',
                    style: TextStyle(
                      fontSize: 9,
                      color: actif ? AppTheme.primaryColor : Colors.red,
                    ),
                  ),
                ),
                if (badgeLibre) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Libre',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}