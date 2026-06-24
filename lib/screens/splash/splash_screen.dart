import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      context.go(AppRoutes.login);
      return;
    }

    // Récupérer le rôle
    final authService = AuthService();
    final role = await authService.getRoleUtilisateurConnecte();

    if (!mounted) return;

    if (role == null || role == 'inactif') {
      await authService.deconnecter();
      context.go(AppRoutes.login);
      return;
    }

    // Redirection selon le rôle
    switch (role) {
      case 'admin':
        context.go(AppRoutes.dashboardAdmin);
        break;
      case 'directeur':
        context.go(AppRoutes.dashboardDirecteur);
        break;
      case 'csi':
        context.go(AppRoutes.dashboardCSI);
        break;
      case 'rapporteur':
        context.go(AppRoutes.dashboardRapporteur);
        break;
      default:
        context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 3),
              ),
              child: const Icon(Icons.school,
                  color: AppTheme.primaryColor, size: 44),
            ),
            const SizedBox(height: 20),
            const Text('DoctoApp',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold)),
            const Text('UJKZ',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w300)),
            const SizedBox(height: 8),
            Container(
                width: 50,
                height: 1,
                color: Colors.white30),
            const SizedBox(height: 8),
            const Text(
                'Suivi des thèses · Gestion des rapporteurs',
                style: TextStyle(
                    color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            ),
            const SizedBox(height: 24),
            const Text('Université Joseph Ki-Zerbo',
                style: TextStyle(
                    color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}