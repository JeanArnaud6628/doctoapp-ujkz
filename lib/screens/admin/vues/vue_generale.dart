import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/admin_provider.dart';
import '../../../services/admin_service.dart';

class VueGenerale extends ConsumerWidget {
  const VueGenerale({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final alertesAsync = ref.watch(alertesProvider);
    final manuscritsAsync = ref.watch(manuscritsEnAttenteProvider);
    final demandesAsync = ref.watch(demandesDirecteurExterneProvider);

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        ref.invalidate(adminStatsProvider);
        ref.invalidate(alertesProvider);
        ref.invalidate(manuscritsEnAttenteProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // Cartes statistiques détaillées
          statsAsync.when(
            data: (s) => _StatsDetaillees(stats: s),
            loading: () => const _Loading(),
            error: (e, _) => _Erreur(e.toString()),
          ),
          const SizedBox(height: 14),
          // Actions rapides
          const _ActionsRapides(),
          const SizedBox(height: 14),
          // Alertes urgentes
          alertesAsync.when(
            data: (a) => a.isEmpty
                ? const SizedBox()
                : _AlertesUrgentes(alertes: a),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 14),
          // Manuscrits en attente
          manuscritsAsync.when(
            data: (m) => m.isEmpty
                ? const SizedBox()
                : _ManuscritsSection(manuscrits: m, ref: ref),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 14),
          // Demandes directeur externe
          demandesAsync.when(
            data: (d) => d.isEmpty
                ? const SizedBox()
                : _DemandesExternesSection(demandes: d, ref: ref),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _StatsDetaillees extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsDetaillees({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LabelSection('VUE D\'ENSEMBLE'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.1,
          children: [
            _MiniStatCard('Doctorants', stats['doctorants'] ?? 0,
                Icons.school_rounded, AppTheme.primaryColor,
                    () => context.push(AppRoutes.gestionDoctorants)),
            _MiniStatCard('Directeurs', stats['directeurs'] ?? 0,
                Icons.person_pin_rounded, const Color(0xFF0D47A1),
                    () => context.push(AppRoutes.gestionDirecteurs)),
            _MiniStatCard('CSI', stats['csi'] ?? 0,
                Icons.groups_rounded, const Color(0xFF00695C),
                    () => context.push(AppRoutes.gestionCSI)),
            _MiniStatCard('Rapporteurs', stats['rapporteurs'] ?? 0,
                Icons.rate_review_rounded, const Color(0xFF6A1B9A),
                    () => context.push(AppRoutes.gestionRapporteurs)),
            _MiniStatCard('Thèses actives', stats['theses_actives'] ?? 0,
                Icons.menu_book_rounded, const Color(0xFFE65100),
                    () => context.push(AppRoutes.gestionTheses)),
            _MiniStatCard('Soutenances', stats['soutenances'] ?? 0,
                Icons.event_available_rounded, const Color(0xFFC62828),
                    () => context.push(AppRoutes.gestionSoutenances)),
          ],
        ),
        const SizedBox(height: 10),
        // Ligne alertes
        const _LabelSection('ACTIONS REQUISES'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _AlerteItem('Rapports att.',
                  stats['rapports_attente'] ?? 0, Colors.orange),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AlerteItem('Quitus Dir.',
                  stats['quitus_dir_manquants'] ?? 0, Colors.red),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AlerteItem('Avis CSI',
                  stats['avis_csi_manquants'] ?? 0, Colors.purple),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _AlerteItem('Manuscrits',
                  stats['manuscrits_attente'] ?? 0, Colors.brown),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AlerteItem('Expertises',
                  stats['expertises_attente'] ?? 0, Colors.teal),
            ),
            const SizedBox(width: 8),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MiniStatCard(
      this.label, this.value, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value.toString(),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlerteItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _AlerteItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: value > 0 ? color.withOpacity(0.08) : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: value > 0
                ? color.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value.toString(),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: value > 0 ? color : Colors.grey)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppTheme.textGray),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ActionsRapides extends StatelessWidget {
  const _ActionsRapides();

  @override
  Widget build(BuildContext context) {
    final actions = [
      {'label': 'Créer\nDirecteur', 'icon': Icons.person_add_rounded, 'color': const Color(0xFF0D47A1), 'route': AppRoutes.ajouterDirecteur},
      {'label': 'Créer\nRapporteur', 'icon': Icons.rate_review_rounded, 'color': const Color(0xFF6A1B9A), 'route': AppRoutes.ajouterRapporteur},
      {'label': 'Créer\nCSI', 'icon': Icons.group_add_rounded, 'color': const Color(0xFF00695C), 'route': AppRoutes.ajouterCSI},
      {'label': 'Envoyer\nNotif.', 'icon': Icons.campaign_rounded, 'color': const Color(0xFFE65100), 'route': AppRoutes.envoyerNotification},
      {'label': 'Planifier\nSoutenance', 'icon': Icons.event_available_rounded, 'color': const Color(0xFFC62828), 'route': AppRoutes.gestionSoutenances},
      {'label': 'Assigner\nRapporteurs', 'icon': Icons.auto_awesome_rounded, 'color': AppTheme.primaryColor, 'route': AppRoutes.gestionTheses},
      {'label': 'Manuscrits\nEn attente', 'icon': Icons.pending_actions_rounded, 'color': const Color(0xFF37474F), 'route': AppRoutes.gestionManuscrits},
      {'label': 'Rapports\nAnnuels', 'icon': Icons.assignment_rounded, 'color': const Color(0xFF1565C0), 'route': AppRoutes.gestionRapports},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LabelSection('ACTIONS RAPIDES'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.9,
          children: actions.map((a) {
            return GestureDetector(
              onTap: () => context.push(a['route'] as String),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: (a['color'] as Color).withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: (a['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(a['icon'] as IconData,
                          color: a['color'] as Color, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(a['label'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w500,
                            height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AlertesUrgentes extends StatelessWidget {
  final List<Map<String, dynamic>> alertes;
  const _AlertesUrgentes({required this.alertes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _LabelSection('ALERTES URGENTES'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(alertes.length.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...alertes.take(5).map((a) {
          final niveau = a['niveau'] as String? ?? 'warning';
          final color = niveau == 'danger' ? Colors.red : Colors.orange;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: color, width: 4)),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                Icon(
                  niveau == 'danger'
                      ? Icons.error_outline
                      : Icons.warning_amber_outlined,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['nom_complet'] as String? ?? '',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text(a['message'] as String? ?? '',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textGray)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    niveau == 'danger' ? 'Urgent' : 'Attention',
                    style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ManuscritsSection extends StatelessWidget {
  final List<Map<String, dynamic>> manuscrits;
  final WidgetRef ref;
  const _ManuscritsSection(
      {required this.manuscrits, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _LabelSection('MANUSCRITS EN ATTENTE'),
            TextButton(
              onPressed: () => context.push(AppRoutes.gestionManuscrits),
              child: const Text('Voir tout',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.primaryColor)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...manuscrits.take(3).map((m) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.orange.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.orange.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.upload_file,
                          color: Color(0xFFE65100), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['titre'] ?? 'Sans titre',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(
                              'Déposé le ${m['date_depot'] ?? '–'}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textGray)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('En attente',
                          style: TextStyle(
                              fontSize: 9,
                              color: AppTheme.orangeColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await AdminService()
                              .rejeterManuscrit(m['id']);
                          ref.invalidate(manuscritsEnAttenteProvider);
                          ref.invalidate(adminStatsProvider);
                        },
                        icon: const Icon(Icons.close,
                            size: 14, color: Colors.red),
                        label: const Text('Rejeter',
                            style: TextStyle(
                                color: Colors.red, fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding:
                          const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final theseId = m['these_id'] as String?;
                          await AdminService().validerManuscrit(
                              m['id'], theseId ?? '');
                          ref.invalidate(manuscritsEnAttenteProvider);
                          ref.invalidate(adminStatsProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Manuscrit validé !'),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check, size: 14),
                        label: const Text('Valider',
                            style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding:
                          const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _DemandesExternesSection extends StatelessWidget {
  final List<Map<String, dynamic>> demandes;
  final WidgetRef ref;
  const _DemandesExternesSection(
      {required this.demandes, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LabelSection('DEMANDES DIRECTEUR EXTERNE'),
        const SizedBox(height: 8),
        ...demandes.map((d) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF0D47A1).withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                    color: Colors.blue.withOpacity(0.04),
                    blurRadius: 6)
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_outlined,
                      color: Color(0xFF0D47A1), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${d['prenom'] ?? ''} ${d['nom'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text(
                          d['universite'] ??
                              d['email'] ??
                              '–',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textGray)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await AdminService()
                        .validerDirecteurExterne(d['id']);
                    ref.invalidate(demandesDirecteurExterneProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Directeur externe validé !'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Text('Valider',
                      style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _LabelSection extends StatelessWidget {
  final String text;
  const _LabelSection(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF4A7A4A),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8));
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14)),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _Erreur extends StatelessWidget {
  final String message;
  const _Erreur(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCDD2))),
      child: Text('Erreur: $message',
          style: const TextStyle(fontSize: 12, color: Colors.red)),
    );
  }
}