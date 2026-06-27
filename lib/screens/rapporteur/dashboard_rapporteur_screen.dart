import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../models/utilisateur_model.dart';

class DashboardRapporteurScreen extends ConsumerStatefulWidget {
  const DashboardRapporteurScreen({super.key});

  @override
  ConsumerState<DashboardRapporteurScreen> createState() =>
      _DashboardRapporteurScreenState();
}

class _DashboardRapporteurScreenState
    extends ConsumerState<DashboardRapporteurScreen> {
  List<Map<String, dynamic>> _expertises = [];
  bool _isLoading = true;
  int _nbEnAttente = 0;
  int _nbTelecharge = 0;
  int _nbDepose = 0;
  int _nbRetard = 0;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('rapports_expertise')
          .select(
          '''
              *,
              theses!these_id(
                id, 
                titre, 
                doctorant_id,
                utilisateurs!doctorant_id(nom, prenom, ine)
              )
              ''')
          .eq('rapporteur_id', user.id)
          .order('created_at', ascending: false);

      _expertises = (response as List).cast<Map<String, dynamic>>();

      _nbEnAttente = _expertises.where((e) => e['statut'] == 'en_attente').length;
      _nbTelecharge = _expertises.where((e) => e['statut'] == 'telecharge').length;
      _nbDepose = _expertises.where((e) => e['statut'] == 'depose').length;
      _nbRetard = _expertises.where((e) => e['statut'] == 'retard').length;
    } catch (e) {
      print('Erreur chargement expertises: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.utilisateur;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          _buildHeader(user),
          SliverPadding(
            padding: const EdgeInsets.all(14),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStats(),
                const SizedBox(height: 14),
                _buildExpertisesList(),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 0),
    );
  }

  Widget _buildHeader(UtilisateurModel user) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A5C2A), Color(0xFF2E7D42)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bonjour,',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        user.nomComplet,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Rapporteur',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        user.initiales,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            // TODO: Notifications rapporteur
          },
        ),
      ],
    );
  }

  Widget _buildStats() {
    final items = [
      {'label': 'En attente', 'value': _nbEnAttente, 'color': Colors.orange, 'icon': Icons.pending},
      {'label': 'Téléchargés', 'value': _nbTelecharge, 'color': Colors.blue, 'icon': Icons.download_done},
      {'label': 'Déposés', 'value': _nbDepose, 'color': Colors.green, 'icon': Icons.check_circle},
      {'label': 'En retard', 'value': _nbRetard, 'color': Colors.red, 'icon': Icons.warning},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final value = item['value'] as int;
          final color = item['color'] as Color;
          return Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: value > 0 ? color.withOpacity(0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: value > 0 ? color : Colors.grey,
                  size: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: value > 0 ? color : Colors.grey,
                ),
              ),
              Text(
                item['label'] as String,
                style: TextStyle(
                  fontSize: 8,
                  color: value > 0 ? color : Colors.grey,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpertisesList() {
    return Container(
      padding: const EdgeInsets.all(14),
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
                'MES EXPERTISES',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF4A7A4A),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${_expertises.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_expertises.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.rate_review_outlined,
                        size: 48, color: AppTheme.textGray),
                    SizedBox(height: 12),
                    Text(
                      'Aucune expertise attribuée',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGray,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Vous serez notifié dès qu\'une expertise vous sera affectée.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._expertises.take(3).map((e) {
              return _ExpertiseCard(expertise: e);
            }),
          if (_expertises.length > 3)
            TextButton(
              onPressed: () {
                // TODO: Voir toutes les expertises
              },
              child: const Text(
                'Voir toutes mes expertises',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                ),
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
            context.go(AppRoutes.dashboardRapporteur);
            break;
          case 1:
            context.go(AppRoutes.manuscritRapporteur);
            break;
          case 2:
            context.go(AppRoutes.profilRapporteur);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryColor),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.rate_review_outlined),
          selectedIcon: Icon(Icons.rate_review, color: AppTheme.primaryColor),
          label: 'Expertises',
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

// ═══════════════════════════════════════════════════════════════════════════
// CARTE EXPERTISE
// ═══════════════════════════════════════════════════════════════════════════

class _ExpertiseCard extends StatelessWidget {
  final Map<String, dynamic> expertise;

  const _ExpertiseCard({required this.expertise});

  @override
  Widget build(BuildContext context) {
    final these = expertise['theses'] as Map<String, dynamic>?;
    final doctorant = these?['utilisateurs'] as Map<String, dynamic>?;
    final titre = these?['titre'] as String? ?? 'Thèse';
    final nomDoctorant = doctorant != null
        ? '${doctorant['prenom'] ?? ''} ${doctorant['nom'] ?? ''}'
        : 'Inconnu';
    final ine = doctorant?['ine'] as String? ?? '';

    final statut = expertise['statut'] as String? ?? 'en_attente';
    final dateLimite = expertise['date_limite'] as String?;

    Color statutColor;
    String statutLabel;
    IconData statutIcon;

    if (statut == 'depose') {
      statutColor = Colors.green;
      statutLabel = 'Déposé ✅';
      statutIcon = Icons.check_circle;
    } else if (statut == 'telecharge') {
      statutColor = Colors.blue;
      statutLabel = 'Téléchargé 📥';
      statutIcon = Icons.download_done;
    } else if (statut == 'retard') {
      statutColor = Colors.red;
      statutLabel = 'En retard ❌';
      statutIcon = Icons.warning;
    } else {
      statutColor = Colors.orange;
      statutLabel = 'En attente ⏳';
      statutIcon = Icons.pending;
    }

    return GestureDetector(
      onTap: () {
        if (statut != 'depose') {
          context.push(
            '${AppRoutes.manuscritRapporteur}/${expertise['id']}',
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statut != 'depose'
              ? const Color(0xFFF8FBF8)
              : const Color(0xFFF1F8F1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statutColor.withOpacity(0.3),
            width: statut == 'depose' ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statutIcon, color: statutColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$nomDoctorant ($ine)',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statutLabel,
                    style: TextStyle(
                      fontSize: 9,
                      color: statutColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (dateLimite != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: statut == 'retard' ? Colors.red : AppTheme.textGray,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Date limite : ${DateFormat('dd/MM/yyyy').format(DateTime.parse(dateLimite))}',
                    style: TextStyle(
                      fontSize: 10,
                      color: statut == 'retard' ? Colors.red : AppTheme.textGray,
                      fontWeight: statut == 'retard' ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
            if (statut != 'depose' && statut != 'retard') ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 12, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    statut == 'en_attente'
                        ? '🔒 Téléchargez le manuscrit pour démarrer le chronomètre'
                        : '⏳ ${_calculerJoursRestants(dateLimite)} jours restants',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _calculerJoursRestants(String? dateLimite) {
    if (dateLimite == null) return '0';
    try {
      final fin = DateTime.parse(dateLimite);
      final maintenant = DateTime.now();
      final difference = fin.difference(maintenant).inDays;
      return difference > 0 ? difference.toString() : '0';
    } catch (_) {
      return '0';
    }
  }
}