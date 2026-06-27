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

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        ref.invalidate(adminStatsProvider);
        ref.invalidate(alertesProvider);
        ref.invalidate(manuscritsEnAttenteProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── STATISTIQUES PRINCIPALES ──────────────────────────────
            statsAsync.when(
              data: (s) => _StatsPrincipales(stats: s),
              loading: () => const _LoadingStats(),
              error: (e, _) => _ErrorText(e.toString()),
            ),
            const SizedBox(height: 14),

            // ─── ALERTES ACTIVES ────────────────────────────────────────
            alertesAsync.when(
              data: (a) => a.isEmpty ? const SizedBox() : _AlertesList(alertes: a),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 14),

            // ─── MANUSCRITS EN ATTENTE ─────────────────────────────────
            manuscritsAsync.when(
              data: (m) => m.isEmpty ? const SizedBox() : _ManuscritsSection(manuscrits: m, ref: ref),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 14),

            // ─── ACTIONS RAPIDES ────────────────────────────────────────
            const _ActionsRapides(),
            const SizedBox(height: 14),

            // ─── STATISTIQUES SECONDAIRES ──────────────────────────────
            statsAsync.when(
              data: (s) => _StatsSecondaires(stats: s),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATISTIQUES PRINCIPALES
// ═══════════════════════════════════════════════════════════════════════════

class _StatsPrincipales extends StatelessWidget {
  final Map<String, int> stats;

  const _StatsPrincipales({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'Doctorants', 'value': stats['doctorants'] ?? 0, 'icon': Icons.school, 'color': AppTheme.primaryColor},
      {'label': 'Directeurs', 'value': stats['directeurs'] ?? 0, 'icon': Icons.person_pin, 'color': const Color(0xFF0D47A1)},
      {'label': 'Rapporteurs', 'value': stats['rapporteurs'] ?? 0, 'icon': Icons.rate_review, 'color': const Color(0xFF6A1B9A)},
      {'label': 'CSI', 'value': stats['csi'] ?? 0, 'icon': Icons.groups, 'color': const Color(0xFF00695C)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _StatCard(
          label: item['label'] as String,
          value: item['value'] as int,
          icon: item['icon'] as IconData,
          color: item['color'] as Color,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
// STATISTIQUES SECONDAIRES (Alertes)
// ═══════════════════════════════════════════════════════════════════════════

class _StatsSecondaires extends StatelessWidget {
  final Map<String, int> stats;

  const _StatsSecondaires({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'Rapports att.', 'value': stats['rapports_attente'] ?? 0, 'color': Colors.orange},
      {'label': 'Quitus Dir.', 'value': stats['quitus_dir_manquants'] ?? 0, 'color': Colors.red},
      {'label': 'Avis CSI', 'value': stats['avis_csi_manquants'] ?? 0, 'color': const Color(0xFF6A1B9A)},
      {'label': 'Manuscrits', 'value': stats['manuscrits_attente'] ?? 0, 'color': Colors.brown},
      {'label': 'Expertises', 'value': stats['expertises_attente'] ?? 0, 'color': Colors.teal},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTIONS REQUISES',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF4A7A4A),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final value = item['value'] as int;
              final color = item['color'] as Color;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: value > 0 ? color.withOpacity(0.1) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: value > 0 ? color.withOpacity(0.3) : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: value > 0 ? color : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: value > 0 ? color : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ALERTES
// ═══════════════════════════════════════════════════════════════════════════

class _AlertesList extends StatelessWidget {
  final List<Map<String, dynamic>> alertes;

  const _AlertesList({required this.alertes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              const Text(
                'ALERTES URGENTES',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  alertes.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...alertes.take(3).map((a) {
            final niveau = a['niveau'] as String? ?? 'warning';
            final color = niveau == 'danger' ? Colors.red : Colors.orange;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(left: BorderSide(color: color, width: 3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      niveau == 'danger' ? Icons.error_outline : Icons.warning_amber_outlined,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['nom_complet'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            a['message'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        niveau == 'danger' ? 'Urgent' : 'Attention',
                        style: TextStyle(
                          fontSize: 8,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (alertes.length > 3)
            TextButton(
              onPressed: () {},
              child: const Text(
                'Voir toutes les alertes',
                style: TextStyle(fontSize: 11, color: AppTheme.primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MANUSCRITS EN ATTENTE
// ═══════════════════════════════════════════════════════════════════════════

class _ManuscritsSection extends StatelessWidget {
  final List<Map<String, dynamic>> manuscrits;
  final WidgetRef ref;

  const _ManuscritsSection({required this.manuscrits, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.04),
            blurRadius: 8,
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
              const Text(
                'MANUSCRITS EN ATTENTE',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF4A7A4A),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.gestionManuscrits),
                child: const Text(
                  'Voir tout',
                  style: TextStyle(fontSize: 11, color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...manuscrits.take(2).map((m) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.upload_file, color: Color(0xFFE65100), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['titre'] ?? 'Sans titre',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Déposé le ${m['date_depot'] ?? '–'}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          await AdminService().rejeterManuscrit(m['id']);
                          ref.invalidate(manuscritsEnAttenteProvider);
                          ref.invalidate(adminStatsProvider);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Rejeter', style: TextStyle(fontSize: 9, color: Colors.red)),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () async {
                          await AdminService().validerManuscrit(m['id'], m['these_id'] ?? '');
                          ref.invalidate(manuscritsEnAttenteProvider);
                          ref.invalidate(adminStatsProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Manuscrit validé !'),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Valider', style: TextStyle(fontSize: 9, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTIONS RAPIDES
// ═══════════════════════════════════════════════════════════════════════════

class _ActionsRapides extends StatelessWidget {
  const _ActionsRapides();

  @override
  Widget build(BuildContext context) {
    final actions = [
      {'label': 'Ajouter Doctorant', 'icon': Icons.person_add, 'color': AppTheme.primaryColor, 'route': AppRoutes.ajouterDoctorant},
      {'label': 'Ajouter Directeur', 'icon': Icons.person_pin, 'color': const Color(0xFF0D47A1), 'route': AppRoutes.ajouterDirecteur},
      {'label': 'Ajouter Rapporteur', 'icon': Icons.rate_review, 'color': const Color(0xFF6A1B9A), 'route': AppRoutes.ajouterRapporteur},
      {'label': 'Ajouter CSI', 'icon': Icons.group_add, 'color': const Color(0xFF00695C), 'route': AppRoutes.ajouterCSI},
      {'label': 'Planifier Soutenance', 'icon': Icons.event_available, 'color': const Color(0xFFC62828), 'route': AppRoutes.gestionSoutenances},
      {'label': 'Attribuer Rapporteurs', 'icon': Icons.auto_awesome, 'color': const Color(0xFFE65100), 'route': AppRoutes.gestionTheses},
      {'label': 'Envoyer Notification', 'icon': Icons.campaign, 'color': const Color(0xFF1565C0), 'route': AppRoutes.envoyerNotification},
      {'label': 'Gérer Manuscrits', 'icon': Icons.upload_file, 'color': const Color(0xFF37474F), 'route': AppRoutes.gestionManuscrits},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTIONS RAPIDES',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF4A7A4A),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions.map((a) {
              return GestureDetector(
                onTap: () => context.push(a['route'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (a['color'] as Color).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (a['color'] as Color).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(a['icon'] as IconData, size: 14, color: a['color'] as Color),
                      const SizedBox(width: 4),
                      Text(
                        a['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: a['color'] as Color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOADING / ERROR
// ═══════════════════════════════════════════════════════════════════════════

class _LoadingStats extends StatelessWidget {
  const _LoadingStats();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;

  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Text(
        'Erreur: $message',
        style: const TextStyle(fontSize: 12, color: Colors.red),
      ),
    );
  }
}