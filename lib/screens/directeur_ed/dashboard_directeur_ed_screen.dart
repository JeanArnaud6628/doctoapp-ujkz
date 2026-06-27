import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../models/utilisateur_model.dart';

class DashboardDirecteurEDScreen extends ConsumerStatefulWidget {
  const DashboardDirecteurEDScreen({super.key});

  @override
  ConsumerState<DashboardDirecteurEDScreen> createState() =>
      _DashboardDirecteurEDScreenState();
}

class _DashboardDirecteurEDScreenState
    extends ConsumerState<DashboardDirecteurEDScreen> {
  bool _isLoading = true;
  int _nbDoctorants = 0;
  int _nbTheses = 0;
  int _nbSoutenances = 0;
  int _nbProrogationsEnAttente = 0;
  int _nbCasException = 0;
  int _nbRapportsEnRetard = 0;
  String _ecole = '';

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Récupérer l'école du Directeur ED
      final userData = await Supabase.instance.client
          .from('utilisateurs')
          .select('ecole_doctorale')
          .eq('id', user.id)
          .single();

      _ecole = userData['ecole_doctorale'] as String? ?? '';

      if (_ecole.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // Statistiques de l'école
      final doctorants = await Supabase.instance.client
          .from('utilisateurs')
          .select('id')
          .eq('role', 'doctorant')
          .eq('ecole_doctorale', _ecole)
          .eq('actif', true);

      _nbDoctorants = (doctorants as List).length;

      final theses = await Supabase.instance.client
          .from('theses')
          .select('id')
          .eq('ecole_doctorale', _ecole)
          .neq('etat', 'soutenue');

      _nbTheses = (theses as List).length;

      final soutenances = await Supabase.instance.client
          .from('soutenances')
          .select('id')
          .eq('ecole_doctorale', _ecole);

      _nbSoutenances = (soutenances as List).length;

      // Prorogations en attente
      final prorogations = await Supabase.instance.client
          .from('prorogations')
          .select('id')
          .eq('ecole_doctorale', _ecole)
          .eq('decision', 'en_attente');

      _nbProrogationsEnAttente = (prorogations as List).length;

      // Cas d'exception
      final exceptions = await Supabase.instance.client
          .from('signalements')
          .select('id')
          .eq('ecole_doctorale', _ecole)
          .eq('statut', 'en_attente');

      _nbCasException = (exceptions as List).length;

      // Rapports en retard
      final doctorantIds = (doctorants as List).map((d) => d['id'] as String).toList();
      if (doctorantIds.isNotEmpty) {
        final rapports = await Supabase.instance.client
            .from('rapports_avancement')
            .select('id')
            .inFilter('doctorant_id', doctorantIds)
            .eq('statut', 'en_attente')
            .lt('date_limite', DateTime.now().toIso8601String().split('T')[0]);

        _nbRapportsEnRetard = (rapports as List).length;
      }
    } catch (e) {
      print('Erreur chargement données: $e');
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
                _buildAlertes(),
                const SizedBox(height: 14),
                _buildActionsRapides(),
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
      expandedHeight: 160,
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
                      Text(
                        'Directeur ${_ecole.isNotEmpty ? _ecole : "École Doctorale"}',
                        style: const TextStyle(
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
            // TODO: Notifications Directeur ED
          },
        ),
      ],
    );
  }

  Widget _buildStats() {
    final items = [
      {'label': 'Doctorants', 'value': _nbDoctorants, 'icon': Icons.school, 'color': AppTheme.primaryColor},
      {'label': 'Thèses actives', 'value': _nbTheses, 'icon': Icons.menu_book, 'color': const Color(0xFF0D47A1)},
      {'label': 'Soutenances', 'value': _nbSoutenances, 'icon': Icons.event, 'color': const Color(0xFF00695C)},
      {'label': 'Prorogations', 'value': _nbProrogationsEnAttente, 'icon': Icons.pending, 'color': Colors.orange},
      {'label': 'Cas exception', 'value': _nbCasException, 'icon': Icons.warning, 'color': Colors.red},
      {'label': 'Rapports en retard', 'value': _nbRapportsEnRetard, 'icon': Icons.assignment_late, 'color': Colors.red},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final value = item['value'] as int;
        final color = item['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item['icon'] as IconData, color: color, size: 16),
              ),
              const SizedBox(height: 4),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                item['label'] as String,
                style: const TextStyle(
                  fontSize: 8,
                  color: AppTheme.textGray,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertes() {
    final alertes = [];

    if (_nbProrogationsEnAttente > 0) {
      alertes.add({
        'message': '$_nbProrogationsEnAttente demande(s) de prorogation en attente',
        'color': Colors.orange,
        'icon': Icons.pending,
        'route': AppRoutes.prorogationsDirecteurED,
      });
    }

    if (_nbCasException > 0) {
      alertes.add({
        'message': '$_nbCasException cas d\'exception à traiter',
        'color': Colors.red,
        'icon': Icons.warning,
        'route': AppRoutes.casExceptionDirecteurED,
      });
    }

    if (_nbRapportsEnRetard > 0) {
      alertes.add({
        'message': '$_nbRapportsEnRetard rapport(s) en retard',
        'color': Colors.red,
        'icon': Icons.assignment_late,
        'route': AppRoutes.statistiquesDirecteurED,
      });
    }

    if (alertes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '✅ Tout est en ordre dans votre école doctorale',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ALERTES',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF4A7A4A),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ...alertes.map((a) {
            final color = a['color'] as Color;
            return GestureDetector(
              onTap: () => context.push(a['route'] as String),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(left: BorderSide(color: color, width: 3)),
                ),
                child: Row(
                  children: [
                    Icon(a['icon'] as IconData, color: color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a['message'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: color.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionsRapides() {
    final actions = [
      {'label': 'Prorogations', 'icon': Icons.calendar_today, 'color': Colors.orange, 'route': AppRoutes.prorogationsDirecteurED},
      {'label': 'Cas exception', 'icon': Icons.warning, 'color': Colors.red, 'route': AppRoutes.casExceptionDirecteurED},
      {'label': 'Statistiques', 'icon': Icons.bar_chart, 'color': Colors.blue, 'route': AppRoutes.statistiquesDirecteurED},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
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
              fontSize: 11,
              color: Color(0xFF4A7A4A),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: actions.map((a) {
              final color = a['color'] as Color;
              return GestureDetector(
                onTap: () => context.push(a['route'] as String),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(a['icon'] as IconData, color: color, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a['label'] as String,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textGray,
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

  Widget _buildBottomNav(BuildContext context, int index) {
    return NavigationBar(
      selectedIndex: index,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE8F5E9),
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go(AppRoutes.dashboardDirecteurED);
            break;
          case 1:
            context.go(AppRoutes.prorogationsDirecteurED);
            break;
          case 2:
            context.go(AppRoutes.statistiquesDirecteurED);
            break;
          case 3:
            context.go(AppRoutes.profilDirecteurED);
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
          icon: Icon(Icons.pending_outlined),
          selectedIcon: Icon(Icons.pending, color: AppTheme.primaryColor),
          label: 'Prorogations',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart, color: AppTheme.primaryColor),
          label: 'Stats',
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