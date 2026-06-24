import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/these_provider.dart';
import '../../../services/these_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const Scaffold();

    final notifsAsync = ref.watch(notificationsProvider(user.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Tout lire',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
      body: notifsAsync.when(
        data: (notifs) => notifs.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none,
                  size: 64, color: AppTheme.primaryColor),
              SizedBox(height: 16),
              Text('Aucune notification',
                  style: TextStyle(fontSize: 16)),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: notifs.length,
          itemBuilder: (context, index) {
            final n = notifs[index];
            return GestureDetector(
              onTap: () async {
                await ref
                    .read(theseServiceProvider)
                    .marquerNotificationLue(n.id);
                ref.invalidate(notificationsProvider(user.id));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: n.lu
                      ? Colors.white
                      : const Color(0xFFF8FCF8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border(
                    left: BorderSide(
                      color: n.lu
                          ? Colors.transparent
                          : AppTheme.primaryColor,
                      width: 3,
                    ),
                    right: const BorderSide(
                        color: Color(0xFFDDE8DD), width: 0.5),
                    top: const BorderSide(
                        color: Color(0xFFDDE8DD), width: 0.5),
                    bottom: const BorderSide(
                        color: Color(0xFFDDE8DD), width: 0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications,
                          color: AppTheme.primaryColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(n.titre,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: n.lu
                                      ? FontWeight.normal
                                      : FontWeight.w500)),
                          const SizedBox(height: 3),
                          Text(n.message,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textGray)),
                        ],
                      ),
                    ),
                    if (!n.lu)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () =>
        const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
      bottomNavigationBar: _buildBottomNav(context, 2),
    );
  }

  Widget _buildBottomNav(BuildContext context, int index) {
    return NavigationBar(
      selectedIndex: index,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE8F5E9),
      onDestinationSelected: (i) {
        switch (i) {
          case 0: context.go(AppRoutes.dashboard); break;
          case 1: context.go(AppRoutes.these); break;
          case 2: context.go(AppRoutes.notifications); break;
          case 3: context.go(AppRoutes.opportunites); break;
          case 4: context.go(AppRoutes.profil); break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppTheme.primaryColor), label: 'Accueil'),
        NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description, color: AppTheme.primaryColor), label: 'Thèse'),
        NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications, color: AppTheme.primaryColor), label: 'Alertes'),
        NavigationDestination(icon: Icon(Icons.lightbulb_outlined), selectedIcon: Icon(Icons.lightbulb, color: AppTheme.primaryColor), label: 'Opportunités'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor), label: 'Profil'),
      ],
    );
  }
}