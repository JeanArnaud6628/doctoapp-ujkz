import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/routes/app_routes.dart';
import '../services/auth_service.dart';

class PlaceholderScreen extends StatelessWidget {
  final String titre;
  const PlaceholderScreen({super.key, required this.titre});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(titre),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () async {
              await AuthService().deconnecter();
              if (context.mounted) context.go(AppRoutes.login);
            },
            child: const Text('Déconnexion',
                style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction,
                size: 64, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text('Module $titre',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('En cours de développement',
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textGray)),
          ],
        ),
      ),
    );
  }
}