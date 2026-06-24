import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _ineController = TextEditingController();
  final _mdpController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _erreur;

  final _authService = AuthService();

  @override
  void dispose() {
    _ineController.dispose();
    _mdpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header vert
          Container(
            color: AppTheme.primaryColor,
            padding: const EdgeInsets.only(
                top: 60, bottom: 40, left: 24, right: 24),
            width: double.infinity,
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2),
                  ),
                  child: const Icon(Icons.school,
                      color: AppTheme.primaryColor, size: 32),
                ),
                const SizedBox(height: 12),
                const Text('DoctoApp UJKZ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                const Text('Accès sécurisé à votre espace',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          // Card blanche
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              transform: Matrix4.translationValues(0, -16, 0),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Connexion',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor)),
                    const SizedBox(height: 4),
                    const Text(
                        'Utilisez votre INE pour accéder à votre espace',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGray)),
                    const SizedBox(height: 20),
                    // INE
                    const Text('INE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor)),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _ineController,
                      hintText: 'Ex : BF2021XXXXXXXXX',
                      prefixIcon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 14),
                    // Mot de passe
                    const Text('Mot de passe',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor)),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _mdpController,
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscure,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppTheme.textGray,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                    if (_erreur != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFFFCDD2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_erreur!,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Se connecter',
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12),
                          child: Text('Première fois ?',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500])),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.go(AppRoutes.createAccount),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 1.5),
                        minimumSize:
                        const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Créer mon compte',
                          style: TextStyle(
                              fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7F0),
                        border: Border.all(
                            color: const Color(0xFFC8DFC8)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: AppTheme.primaryColor,
                              size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Votre INE vous a été fourni lors de votre inscription administrative à l\'UJKZ.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF444444),
                                  height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      _erreur = null;
      _isLoading = true;
    });

    final ine = _ineController.text.trim();
    final mdp = _mdpController.text;

    if (ine.isEmpty || mdp.isEmpty) {
      setState(() {
        _erreur = 'Veuillez remplir tous les champs.';
        _isLoading = false;
      });
      return;
    }

    final result = await _authService.connecter(ine, mdp);

    if (!mounted) return;

    if (result['success'] == true) {
      final role = result['role'] as String;
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
    } else {
      setState(() {
        _erreur = result['message'] as String;
        _isLoading = false;
      });
    }
  }
}