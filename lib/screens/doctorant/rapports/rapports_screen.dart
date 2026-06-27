import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/these_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/rapport_model.dart';

class RapportsScreen extends ConsumerWidget {
  const RapportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.utilisateur;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final rapportsAsync = ref.watch(rapportsProvider(user.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mes Rapports Annuels'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.deposerRapport),
            tooltip: 'Déposer un rapport',
          ),
        ],
      ),
      body: rapportsAsync.when(
        data: (rapports) {
          if (rapports.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async {
              ref.invalidate(rapportsProvider(user.id));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rapports.length,
              itemBuilder: (context, index) {
                final r = rapports[index];
                return _buildRapportCard(r);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur: $e',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(rapportsProvider(user.id));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text(
                  'Réessayer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.deposerRapport),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 64,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun rapport déposé',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Déposez votre premier rapport annuel',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push(AppRoutes.deposerRapport),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text(
              'Déposer un rapport',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRapportCard(RapportModel r) {
    final isValide = r.statut == 'valide';
    final isAttente = r.statut == 'en attente';
    final isRejete = r.statut == 'rejete';

    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;

    if (isValide) {
      statusColor = Colors.green;
      statusBg = const Color(0xFFE8F5E9);
      statusLabel = 'Validé ✅';
      statusIcon = Icons.check_circle;
    } else if (isAttente) {
      statusColor = const Color(0xFFE65100);
      statusBg = const Color(0xFFFFF3E0);
      statusLabel = 'En attente ⏳';
      statusIcon = Icons.pending;
    } else if (isRejete) {
      statusColor = Colors.red;
      statusBg = const Color(0xFFFFEBEE);
      statusLabel = 'Rejeté ❌';
      statusIcon = Icons.cancel;
    } else {
      statusColor = Colors.grey;
      statusBg = const Color(0xFFF3F3F3);
      statusLabel = 'Inconnu';
      statusIcon = Icons.help_outline;
    }

    // Vérifier les avis
    final avisDirecteur = r.avisDirecteur ?? 'en_attente';
    final avisCsi = r.avisCsi ?? 'en_attente';

    String avisDirecteurLabel;
    Color avisDirecteurColor;
    if (avisDirecteur == 'favorable') {
      avisDirecteurLabel = '✅ Favorable';
      avisDirecteurColor = Colors.green;
    } else if (avisDirecteur == 'defavorable') {
      avisDirecteurLabel = '❌ Défavorable';
      avisDirecteurColor = Colors.red;
    } else {
      avisDirecteurLabel = '⏳ En attente';
      avisDirecteurColor = Colors.orange;
    }

    String avisCsiLabel;
    Color avisCsiColor;
    if (avisCsi == 'favorable') {
      avisCsiLabel = '✅ Favorable';
      avisCsiColor = Colors.green;
    } else if (avisCsi == 'defavorable') {
      avisCsiLabel = '❌ Défavorable';
      avisCsiColor = Colors.red;
    } else if (avisCsi == 'signalement') {
      avisCsiLabel = '⚠️ Signalement';
      avisCsiColor = Colors.red;
    } else {
      avisCsiLabel = '⏳ En attente';
      avisCsiColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: isValide ? 1.5 : 0.5,
        ),
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
          // ─── En-tête ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.titre ?? 'Rapport Année ${r.annee}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Année ${r.annee}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textGray,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppTheme.textGray,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Déposé le ${r.dateDepot}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),

          // ─── Avis ─────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildAvisItem(
                  label: 'Directeur',
                  status: avisDirecteurLabel,
                  color: avisDirecteurColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAvisItem(
                  label: 'CSI',
                  status: avisCsiLabel,
                  color: avisCsiColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvisItem({
    required String label,
    required String status,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              status,
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

  Widget _buildBottomNav(BuildContext context, int index) {
    return NavigationBar(
      selectedIndex: index,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE8F5E9),
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go(AppRoutes.dashboard);
            break;
          case 1:
            context.go(AppRoutes.these);
            break;
          case 2:
            context.go(AppRoutes.notifications);
            break;
          case 3:
            context.go(AppRoutes.opportunites);
            break;
          case 4:
            context.go(AppRoutes.profil);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppTheme.primaryColor),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description, color: AppTheme.primaryColor),
          label: 'Thèse',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications, color: AppTheme.primaryColor),
          label: 'Alertes',
        ),
        NavigationDestination(
          icon: Icon(Icons.lightbulb_outlined),
          selectedIcon: Icon(Icons.lightbulb, color: AppTheme.primaryColor),
          label: 'Opportunités',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor),
          label: 'Profil',
        ),
      ],
    );
  }
}