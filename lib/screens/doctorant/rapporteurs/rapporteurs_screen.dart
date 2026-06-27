import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/these_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/these_model.dart';

class RapporteursScreen extends ConsumerStatefulWidget {
  const RapporteursScreen({super.key});

  @override
  ConsumerState<RapporteursScreen> createState() => _RapporteursScreenState();
}

class _RapporteursScreenState extends ConsumerState<RapporteursScreen> {
  List<Map<String, dynamic>> _rapporteurs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerRapporteurs();
  }

  Future<void> _chargerRapporteurs() async {
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
        // Récupérer les rapporteurs
        final rapports = await Supabase.instance.client
            .from('rapports_expertise')
            .select(
            '*, utilisateurs!rapporteur_id(id, nom, prenom, grade, email)')
            .eq('these_id', these['id'])
            .order('created_at');

        _rapporteurs = (rapports as List).cast<Map<String, dynamic>>();
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
        title: const Text('Mes Rapporteurs'),
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
    final aRapporteurs = etape == 'rapporteurs_affectes' ||
        etape == 'evaluation_rapporteurs' ||
        etape == 'soutenance_programmee' ||
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
              color: aRapporteurs
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: aRapporteurs ? AppTheme.primaryColor : AppTheme.orangeColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  aRapporteurs ? Icons.check_circle : Icons.warning_amber_outlined,
                  color: aRapporteurs ? AppTheme.primaryColor : AppTheme.orangeColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    aRapporteurs
                        ? '✅ Des rapporteurs ont été désignés pour votre thèse.'
                        : '⏳ Les rapporteurs seront désignés après validation de votre manuscrit.',
                    style: TextStyle(
                      fontSize: 12,
                      color: aRapporteurs ? AppTheme.primaryColor : AppTheme.orangeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_isLoading) ...[
            const Center(child: CircularProgressIndicator()),
          ] else if (_rapporteurs.isEmpty) ...[
            _buildAucunRapporteur(),
          ] else ...[
            ..._rapporteurs.map((r) => _buildRapporteurCard(r)),
          ],
        ],
      ),
    );
  }

  Widget _buildAucunRapporteur() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.rate_review_outlined,
              size: 48, color: AppTheme.primaryColor),
          const SizedBox(height: 12),
          const Text(
            'Aucun rapporteur désigné',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les rapporteurs seront désignés par l\'administration après validation de votre manuscrit final.',
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

  Widget _buildRapporteurCard(Map<String, dynamic> r) {
    final statut = r['statut'] as String? ?? 'en_attente';
    final dateLimite = r['date_limite'] as String?;
    final utilisateur = r['utilisateurs'] as Map<String, dynamic>?;

    Color statutColor;
    String statutLabel;
    IconData statutIcon;

    if (statut == 'depose') {
      statutColor = Colors.green;
      statutLabel = 'Rapport déposé ✅';
      statutIcon = Icons.check_circle;
    } else if (statut == 'en_attente') {
      statutColor = Colors.orange;
      statutLabel = 'En attente ⏳';
      statutIcon = Icons.pending;
    } else if (statut == 'retard') {
      statutColor = Colors.red;
      statutLabel = 'En retard ❌';
      statutIcon = Icons.warning;
    } else {
      statutColor = Colors.grey;
      statutLabel = statut;
      statutIcon = Icons.help_outline;
    }

    final nom = utilisateur != null
        ? '${utilisateur['prenom'] ?? ''} ${utilisateur['nom'] ?? ''}'
        : 'Rapporteur inconnu';
    final grade = utilisateur?['grade'] as String? ?? '';
    final email = utilisateur?['email'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statutColor.withOpacity(0.3),
          width: statut == 'depose' ? 1.5 : 0.5,
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
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statutColor.withOpacity(0.15),
                child: Text(
                  nom.isNotEmpty ? nom[0].toUpperCase() : 'R',
                  style: TextStyle(
                    color: statutColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (grade.isNotEmpty)
                      Text(
                        grade,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGray,
                        ),
                      ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textGray,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statutLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: statutColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (dateLimite != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: AppTheme.textGray),
                const SizedBox(width: 6),
                Text(
                  'Date limite : $dateLimite',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ],
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