import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/historique_model.dart';

class VueAlertesHistorique extends ConsumerStatefulWidget {
  const VueAlertesHistorique({super.key});

  @override
  ConsumerState<VueAlertesHistorique> createState() =>
      _VueAlertesHistoriqueState();
}

class _VueAlertesHistoriqueState
    extends ConsumerState<VueAlertesHistorique>
    with SingleTickerProviderStateMixin {
  late TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tc,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Alertes actives'),
              Tab(text: 'Historique'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tc,
            children: [
              _TabAlertes(),
              _TabHistorique(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabAlertes extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertesAsync = ref.watch(alertesProvider);

    return alertesAsync.when(
      data: (alertes) => alertes.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64,
                color: AppTheme.primaryColor),
            SizedBox(height: 12),
            Text('Aucune alerte active',
                style: TextStyle(
                    fontSize: 16, color: AppTheme.textGray)),
            SizedBox(height: 6),
            Text('Tout est en ordre !',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textGray)),
          ],
        ),
      )
          : RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async => ref.invalidate(alertesProvider),
        child: ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: alertes.length,
          itemBuilder: (context, index) {
            final a = alertes[index];
            final niveau = a['niveau'] as String? ?? 'warning';
            final color =
            niveau == 'danger' ? Colors.red : Colors.orange;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border(
                    left: BorderSide(color: color, width: 4)),
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      niveau == 'danger'
                          ? Icons.error_rounded
                          : Icons.warning_amber_rounded,
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          a['nom_complet'] as String? ?? '',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          a['message'] as String? ?? '',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textGray),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      niveau == 'danger'
                          ? 'URGENT'
                          : 'ATTENTION',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

class _TabHistorique extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historiqueAsync = ref.watch(historiqueProvider);

    final icones = {
      'etape': Icons.flag_rounded,
      'affectation': Icons.people_rounded,
      'validation': Icons.verified_rounded,
      'soutenance': Icons.event_rounded,
      'notification': Icons.notifications_rounded,
    };

    final couleurs = {
      'etape': AppTheme.primaryColor,
      'affectation': const Color(0xFF0D47A1),
      'validation': const Color(0xFF00695C),
      'soutenance': const Color(0xFFC62828),
      'notification': const Color(0xFFE65100),
    };

    return historiqueAsync.when(
      data: (historique) => historique.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppTheme.primaryColor),
            SizedBox(height: 12),
            Text('Aucun historique disponible',
                style: TextStyle(fontSize: 16, color: AppTheme.textGray)),
          ],
        ),
      )
          : RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async => ref.invalidate(historiqueProvider),
        child: ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: historique.length,
          itemBuilder: (context, index) {
            final h = historique[index];
            final type = h.typeAction ?? 'etape';
            final icon = icones[type] ?? Icons.info_rounded;
            final color = couleurs[type] ?? AppTheme.primaryColor;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    if (index < historique.length - 1)
                      Container(
                        width: 2,
                        height: 24,
                        color: Colors.grey[200],
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(h.action,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        if (h.details != null) ...[
                          const SizedBox(height: 3),
                          Text(h.details!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textGray)),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(h.createdAt),
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppTheme.textGray),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} à ${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}