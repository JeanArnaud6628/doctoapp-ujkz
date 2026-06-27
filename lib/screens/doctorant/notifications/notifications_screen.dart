import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/these_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/these_service.dart';
import '../../../models/notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.utilisateur;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final notifsAsync = ref.watch(notificationsProvider(user.id));
    final nbNonLues = notifsAsync.asData?.value.where((n) => !n.lu).length ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (nbNonLues > 0)
            TextButton(
              onPressed: () => _toutLire(user.id),
              child: Text(
                'Tout lire ($nbNonLues)',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: notifsAsync.when(
        data: (notifs) {
          if (notifs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucune notification',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Vous serez informé des avancées de votre dossier',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async {
              ref.invalidate(notificationsProvider(user.id));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifs.length,
              itemBuilder: (context, index) {
                final n = notifs[index];
                return _buildNotificationItem(n, user.id);
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
                  ref.invalidate(notificationsProvider(user.id));
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
      bottomNavigationBar: _buildBottomNav(context, 2),
    );
  }

  Widget _buildNotificationItem(NotificationModel notif, String userId) {
    final isUnread = !notif.lu;

    return GestureDetector(
      onTap: () async {
        if (isUnread) {
          await ref.read(theseServiceProvider).marquerNotificationLue(notif.id);
          ref.invalidate(notificationsProvider(userId));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFF8FCF8) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color: isUnread ? AppTheme.primaryColor : Colors.transparent,
              width: 3,
            ),
            right: const BorderSide(color: Color(0xFFDDE8DD), width: 0.5),
            top: const BorderSide(color: Color(0xFFDDE8DD), width: 0.5),
            bottom: const BorderSide(color: Color(0xFFDDE8DD), width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isUnread
                    ? const Color(0xFFE8F5E9)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isUnread
                    ? Icons.notifications_active
                    : Icons.notifications,
                color: isUnread
                    ? AppTheme.primaryColor
                    : Colors.grey[400],
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.titre,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                      color: isUnread ? AppTheme.textDark : AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.message,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(notif.createdAt),
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread)
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
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr).toLocal();
      return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _toutLire(String userId) async {
    // TODO: Marquer toutes les notifications comme lues
    // Pour l'instant, on les marque une par une
    final notifs = ref.read(notificationsProvider(userId)).asData?.value ?? [];
    for (final n in notifs.where((n) => !n.lu)) {
      await ref.read(theseServiceProvider).marquerNotificationLue(n.id);
    }
    ref.invalidate(notificationsProvider(userId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toutes les notifications ont été lues'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
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