import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';

class NotificationsAdminScreen extends ConsumerWidget {
  const NotificationsAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsAdminProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
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
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFDDE8DD),
                    width: 0.5),
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications,
                        color: AppTheme.primaryColor,
                        size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(n.titre,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight:
                                FontWeight.w500)),
                        const SizedBox(height: 3),
                        Text(n.message,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textGray)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        loading: () =>
        const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}