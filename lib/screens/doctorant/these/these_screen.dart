import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/these_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/these_model.dart';

class TheseScreen extends ConsumerStatefulWidget {
  const TheseScreen({super.key});

  @override
  ConsumerState<TheseScreen> createState() => _TheseScreenState();
}

class _TheseScreenState extends ConsumerState<TheseScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.utilisateur;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theseAsync = ref.watch(theseProvider(user.id));
    final rapportsAsync = ref.watch(rapportsProvider(user.id));
    final manuscritAsync = ref.watch(manuscritProvider(user.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Ma Thèse'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: theseAsync.when(
        data: (these) {
          if (these == null) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async {
              ref.invalidate(theseProvider(user.id));
              ref.invalidate(rapportsProvider(user.id));
              ref.invalidate(manuscritProvider(user.id));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _buildTheseCard(these),
                  const SizedBox(height: 14),
                  rapportsAsync.when(
                    data: (rapports) => _buildRapportsCard(rapports),
                    loading: () => const _LoadingCard(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 14),
                  manuscritAsync.when(
                    data: (manuscrit) => _buildManuscritCard(manuscrit, these),
                    loading: () => const _LoadingCard(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 14),
                  _buildActionsButtons(these),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildErrorState(),
      ),
      bottomNavigationBar: _buildBottomNav(1),
    );
  }

  // ─── BUILDERS ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 64,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune thèse enregistrée',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push(AppRoutes.enregistrerThese),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text(
              'Enregistrer mon projet',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Erreur de chargement',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
              ref.invalidate(theseProvider(userId));
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
    );
  }

  Widget _buildTheseCard(TheseModel these) {
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
      default:
        etatColor = AppTheme.textGray;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: etatColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  these.etatLibelle,
                  style: TextStyle(
                    color: etatColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'Année ${these.anneeEnCours ?? 1}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            these.titre,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (these.specialite != null) ...[
            const SizedBox(height: 4),
            Text(
              these.specialite!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textGray,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progression',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textGray,
                ),
              ),
              Text(
                '${these.progression}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: etatColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: these.progression / 100,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(etatColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRapportsCard(List rapports) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RAPPORTS ANNUELS',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF4A7A4A),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.rapports),
                child: const Text(
                  'Voir tout',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rapports.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Aucun rapport déposé',
                style: TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 12,
                ),
              ),
            )
          else
            ...rapports.take(3).map((r) {
              final isValide = r.statut == 'valide';
              final isAttente = r.statut == 'en attente';
              final isRejete = r.statut == 'rejete';

              Color statusColor;
              String statusLabel;

              if (isValide) {
                statusColor = Colors.green;
                statusLabel = 'Validé ✅';
              } else if (isAttente) {
                statusColor = Colors.orange;
                statusLabel = 'En attente ⏳';
              } else if (isRejete) {
                statusColor = Colors.red;
                statusLabel = 'Rejeté ❌';
              } else {
                statusColor = Colors.grey;
                statusLabel = r.statut ?? 'Inconnu';
              }

              return ListTile(
                leading: Icon(
                  isValide ? Icons.check_circle : Icons.description,
                  color: isValide ? AppTheme.primaryColor : statusColor,
                ),
                title: Text(
                  r.titre ?? 'Rapport Année ${r.annee}',
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  'Année ${r.annee} · ${r.dateDepot}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 9,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.deposerRapport),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Déposer un rapport'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManuscritCard(dynamic manuscrit, TheseModel these) {
    final aUnManuscrit = manuscrit != null;
    final isValide = aUnManuscrit && manuscrit.statut == 'valide';
    final isAttente = aUnManuscrit && manuscrit.statut == 'en attente';
    final isRejete = aUnManuscrit && manuscrit.statut == 'rejete';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isValide) {
      statusColor = Colors.green;
      statusLabel = 'Validé ✅';
      statusIcon = Icons.check_circle;
    } else if (isAttente) {
      statusColor = Colors.orange;
      statusLabel = 'En attente ⏳';
      statusIcon = Icons.pending;
    } else if (isRejete) {
      statusColor = Colors.red;
      statusLabel = 'Rejeté ❌';
      statusIcon = Icons.cancel;
    } else {
      statusColor = Colors.grey;
      statusLabel = 'Non déposé';
      statusIcon = Icons.upload_file;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: aUnManuscrit ? statusColor.withOpacity(0.3) : const Color(0xFFDDE8DD),
          width: aUnManuscrit ? 1.5 : 0.5,
        ),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manuscrit final',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGray,
                  ),
                ),
                Text(
                  aUnManuscrit ? statusLabel : 'Non déposé',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push(AppRoutes.manuscrit),
            style: ElevatedButton.styleFrom(
              backgroundColor: aUnManuscrit
                  ? (isRejete ? Colors.orange : AppTheme.primaryColor)
                  : AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              aUnManuscrit ? 'Voir' : 'Déposer',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsButtons(TheseModel these) {
    final canEdit = these.etat != 'soutenue';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (canEdit)
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Modifier la thèse
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Modifier les informations'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.deposerRapport),
            icon: const Icon(Icons.assignment_add, size: 18),
            label: const Text('Déposer un rapport annuel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM NAV ─────────────────────────────────────────────────────────

  Widget _buildBottomNav(int index) {
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}