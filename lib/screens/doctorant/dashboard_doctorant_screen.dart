import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/these_provider.dart';
import '../../../models/these_model.dart';
import '../../../models/notification_model.dart';

class DashboardDoctorantScreen extends ConsumerWidget {
  const DashboardDoctorantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.login);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theseAsync = ref.watch(theseProvider(user.id));
    final notifsAsync = ref.watch(notificationsProvider(user.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, user),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                theseAsync.when(
                  data: (these) => these != null
                      ? _buildTheseCard(context, these)
                      : _buildAucuneThese(context),
                  loading: () => const Center(
                      child: CircularProgressIndicator()),
                  error: (e, _) => _buildAucuneThese(context),
                ),
                const SizedBox(height: 10),
                theseAsync.when(
                  data: (these) => _buildParcoursCard(context, these),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 10),
                _buildStatsCard(),
                const SizedBox(height: 10),
                notifsAsync.when(
                  data: (notifs) => _buildNotificationsCard(context, notifs),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 0),
    );
  }

  Widget _buildHeader(BuildContext context, User user) {
    final email = user.email ?? '';
    final ine = email.split('@')[0].toUpperCase();

    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppTheme.primaryColor,
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 12),
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
                      const Text('Bonjour,',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      Text(ine,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w500)),
                      const Text('Université Joseph Ki-Zerbo',
                          style: TextStyle(
                              color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.notifications),
                    child: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 24),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.orangeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Indicateur santé dossier
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSanteItem('Rapport', Colors.green),
                    _buildDivider(),
                    _buildSanteItem('Directeur', Colors.green),
                    _buildDivider(),
                    _buildSanteItem('CSI', Colors.orange),
                    _buildDivider(),
                    _buildSanteItem('Crédits', Colors.green),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSanteItem(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
        width: 1, height: 24, color: Colors.white.withOpacity(0.2));
  }

  Widget _buildTheseCard(BuildContext context, TheseModel these) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MA THÈSE',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4A7A4A),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  these.etatLibelle,
                  style: const TextStyle(
                      color: Color(0xFFC84B00), fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            these.titre,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (these.specialite != null)
            Text(
              these.specialite!,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textGray),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progression globale',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textGray)),
              Text('${these.progression}%',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: these.progression / 100,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAucuneThese(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.description_outlined,
                color: AppTheme.primaryColor, size: 32),
          ),
          const SizedBox(height: 12),
          const Text('Aucun projet de thèse enregistré',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          const Text(
            'Pour activer votre suivi, enregistrez votre projet scientifique.',
            style:
            TextStyle(fontSize: 12, color: AppTheme.textGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.enregistrerThese),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Enregistrer mon projet de thèse'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParcoursCard(BuildContext context, TheseModel? these) {
    final etapes = [
      {
        'titre': 'Enregistrement du sujet',
        'sous': these != null ? 'Enregistré' : 'Non enregistré',
        'done': these != null,
        'active': these == null,
        'icon': Icons.check_circle_outline,
      },
      {
        'titre': 'Rapport annuel',
        'sous': 'À déposer',
        'done': false,
        'active': these != null,
        'icon': Icons.description_outlined,
      },
      {
        'titre': 'Instruction rapporteurs',
        'sous': 'Après dépôt manuscrit',
        'done': false,
        'active': false,
        'icon': Icons.people_outline,
      },
      {
        'titre': 'Soutenance',
        'sous': '–',
        'done': false,
        'active': false,
        'icon': Icons.emoji_events_outlined,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PARCOURS DOCTORAL',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF4A7A4A),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5)),
          const SizedBox(height: 10),
          ...etapes.map((e) => _buildEtapeItem(e)),
        ],
      ),
    );
  }

  Widget _buildEtapeItem(Map<String, dynamic> etape) {
    final bool done = etape['done'] as bool;
    final bool active = etape['active'] as bool;

    Color bgColor = const Color(0xFFFAFAFA);
    Color borderColor = const Color(0xFFE8EEE8);
    Color iconBg = const Color(0xFFEEEEEE);
    Color iconColor = Colors.grey;

    if (done) {
      bgColor = const Color(0xFFF1F8F1);
      iconBg = AppTheme.primaryColor;
      iconColor = Colors.white;
    } else if (active) {
      bgColor = const Color(0xFFE8F5E9);
      borderColor = AppTheme.primaryColor;
      iconBg = Colors.white;
      iconColor = AppTheme.primaryColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
              border: active && !done
                  ? Border.all(
                  color: AppTheme.primaryColor, width: 1.5)
                  : null,
            ),
            child: Icon(
              done ? Icons.check : etape['icon'] as IconData,
              size: 15,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etape['titre'] as String,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
                Text(etape['sous'] as String,
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textGray)),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: done
                  ? const Color(0xFFE8F5E9)
                  : active
                  ? const Color(0xFFFFF3E0)
                  : const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              done
                  ? 'Fait'
                  : active
                  ? 'En cours'
                  : 'En attente',
              style: TextStyle(
                fontSize: 10,
                color: done
                    ? AppTheme.primaryColor
                    : active
                    ? const Color(0xFFC84B00)
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STATISTIQUES RAPIDES',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF4A7A4A),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('0/30', 'Crédits formation'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem('0', 'Rapports déposés'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textGray)),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard(
      BuildContext context, List<NotificationModel> notifs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('NOTIFICATIONS RÉCENTES',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4A7A4A),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5)),
              TextButton(
                onPressed: () =>
                    context.push(AppRoutes.notifications),
                child: const Text('Voir tout',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.primaryColor)),
              ),
            ],
          ),
          if (notifs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucune notification',
                    style: TextStyle(
                        color: AppTheme.textGray, fontSize: 12)),
              ),
            )
          else
            ...notifs.take(3).map((n) => _buildNotifItem(n)),
        ],
      ),
    );
  }

  Widget _buildNotifItem(NotificationModel notif) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 10, top: 4),
            decoration: BoxDecoration(
              color: notif.lu
                  ? Colors.grey
                  : AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif.titre,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: notif.lu
                            ? FontWeight.normal
                            : FontWeight.w500)),
                Text(notif.message,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
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
            label: 'Accueil'),
        NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description,
                color: AppTheme.primaryColor),
            label: 'Thèse'),
        NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications,
                color: AppTheme.primaryColor),
            label: 'Alertes'),
        NavigationDestination(
            icon: Icon(Icons.lightbulb_outlined),
            selectedIcon: Icon(Icons.lightbulb,
                color: AppTheme.primaryColor),
            label: 'Opportunités'),
        NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon:
            Icon(Icons.person, color: AppTheme.primaryColor),
            label: 'Profil'),
      ],
    );
  }
}