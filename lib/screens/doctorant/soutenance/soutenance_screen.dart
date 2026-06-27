import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/these_model.dart';
import '../../../providers/these_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/soutenance_model.dart';

class SoutenanceScreen extends ConsumerStatefulWidget {
  const SoutenanceScreen({super.key});

  @override
  ConsumerState<SoutenanceScreen> createState() => _SoutenanceScreenState();
}

class _SoutenanceScreenState extends ConsumerState<SoutenanceScreen> {
  SoutenanceModel? _soutenance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerSoutenance();
  }

  Future<void> _chargerSoutenance() async {
    final user = ref.read(authProvider).utilisateur;
    if (user == null) return;

    try {
      // Récupérer la thèse du doctorant
      final these = await Supabase.instance.client
          .from('theses')
          .select('id')
          .eq('doctorant_id', user.id)
          .maybeSingle();

      if (these != null) {
        // Récupérer la soutenance
        final response = await Supabase.instance.client
            .from('soutenances')
            .select()
            .eq('these_id', these['id'])
            .maybeSingle();

        if (response != null) {
          _soutenance = SoutenanceModel.fromJson(response);
        }
      }
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.utilisateur;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theseAsync = ref.watch(theseProvider(user.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Ma Soutenance'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: theseAsync.when(
        data: (these) {
          if (these == null) {
            return _buildErrorState(
              'Vous devez d\'abord enregistrer votre sujet de thèse.',
            );
          }
          return _buildContenu(these);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildErrorState(
          'Impossible de charger votre thèse.',
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_outlined,
                size: 64, color: AppTheme.orangeColor),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.enregistrerThese),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text(
                'Enregistrer mon sujet',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu(TheseModel these) {
    final etape = these.etapeActuelle ?? 'enregistree';
    final aSoutenance = etape == 'soutenance_programmee' ||
        etape == 'soutenance_realisee';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Message d'information ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: aSoutenance
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: aSoutenance ? AppTheme.primaryColor : AppTheme.orangeColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  aSoutenance ? Icons.check_circle : Icons.warning_amber_outlined,
                  color: aSoutenance ? AppTheme.primaryColor : AppTheme.orangeColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    aSoutenance
                        ? '✅ Votre soutenance est programmée.'
                        : '⏳ La soutenance sera programmée après validation des rapports.',
                    style: TextStyle(
                      fontSize: 12,
                      color: aSoutenance ? AppTheme.primaryColor : AppTheme.orangeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_isLoading) ...[
            const Center(child: CircularProgressIndicator()),
          ] else if (_soutenance != null) ...[
            _buildSoutenanceCard(),
          ] else if (aSoutenance) ...[
            _buildAucuneSoutenance(),
          ] else ...[
            _buildEnAttente(),
          ],
        ],
      ),
    );
  }

  Widget _buildSoutenanceCard() {
    final s = _soutenance!;
    final estRealisee = s.statut == 'realisee';
    final estProgrammee = s.statut == 'programmee';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (estRealisee) {
      statusColor = Colors.green;
      statusLabel = 'Réalisée ✅';
      statusIcon = Icons.celebration;
    } else if (estProgrammee) {
      statusColor = Colors.blue;
      statusLabel = 'Programmée 📅';
      statusIcon = Icons.event_available;
    } else {
      statusColor = Colors.orange;
      statusLabel = s.statutLibelle;
      statusIcon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: estRealisee ? 1.5 : 0.5,
        ),
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
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Soutenance',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textGray,
                      ),
                    ),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          _buildInfoRow('Date', s.dateSoutenance),
          _buildInfoRow('Heure', s.heure),
          _buildInfoRow('Lieu', s.lieu),
          _buildInfoRow('Président du jury', s.presidentJury),

          if (estRealisee) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Résultat', s.resultatLibelle,
                color: s.resultat == 'admis' ? Colors.green : Colors.red),
            if (s.mention != null) _buildInfoRow('Mention', s.mention!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: color ?? AppTheme.textDark,
                fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAucuneSoutenance() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_busy,
              size: 48, color: Colors.orange),
          const SizedBox(height: 12),
          const Text(
            'Soutenance non trouvée',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Veuillez contacter l\'administration.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnAttente() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_available,
              size: 48, color: AppTheme.primaryColor),
          const SizedBox(height: 12),
          const Text(
            'Soutenance à venir',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'La soutenance sera programmée une fois que tous les rapports d\'expertise auront été déposés.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM NAV ─────────────────────────────────────────────────────────

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