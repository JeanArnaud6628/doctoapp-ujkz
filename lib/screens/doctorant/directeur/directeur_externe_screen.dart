import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/these_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/these_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_textfield.dart';

class DirecteurExterneScreen extends ConsumerStatefulWidget {
  const DirecteurExterneScreen({super.key});

  @override
  ConsumerState<DirecteurExterneScreen> createState() =>
      _DirecteurExterneScreenState();
}

class _DirecteurExterneScreenState
    extends ConsumerState<DirecteurExterneScreen> {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _universiteController = TextEditingController();
  final _gradeController = TextEditingController();
  final _paysController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

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
        title: const Text('Directeur externe'),
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
          return _buildFormulaire(these);
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

  Widget _buildFormulaire(dynamic these) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE0A0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppTheme.orangeColor, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Proposez un directeur externe si aucun professeur de votre école doctorale ne correspond à votre sujet de thèse.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFC84B00),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
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
                const Text(
                  'Informations du directeur externe',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'L\'administration validera cette demande.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 16),

                _buildLabel('Prénom *'),
                CustomTextField(
                  controller: _prenomController,
                  hintText: 'Prénom du directeur',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 12),

                _buildLabel('Nom *'),
                CustomTextField(
                  controller: _nomController,
                  hintText: 'Nom du directeur',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 12),

                _buildLabel('Email *'),
                CustomTextField(
                  controller: _emailController,
                  hintText: 'email@universite.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                _buildLabel('Université *'),
                CustomTextField(
                  controller: _universiteController,
                  hintText: 'Nom de l\'université',
                  prefixIcon: Icons.school_outlined,
                ),
                const SizedBox(height: 12),

                _buildLabel('Grade *'),
                CustomTextField(
                  controller: _gradeController,
                  hintText: 'Ex: Professeur, Maître de conférences...',
                  prefixIcon: Icons.work_outlined,
                ),
                const SizedBox(height: 12),

                _buildLabel('Pays'),
                CustomTextField(
                  controller: _paysController,
                  hintText: 'Pays d\'origine',
                  prefixIcon: Icons.public_outlined,
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF5FB),
                    border: Border.all(color: const Color(0xFFB3D9F0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFF0D47A1), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Une fois votre demande validée par l\'administration, vous pourrez le sélectionner comme directeur.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'Envoyer la demande',
                  isLoading: _isLoading,
                  onPressed: () => _envoyerDemande(these),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Future<void> _envoyerDemande(dynamic these) async {
    if (_prenomController.text.isEmpty ||
        _nomController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _universiteController.text.isEmpty ||
        _gradeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remplissez tous les champs obligatoires'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(theseServiceProvider).demanderDirecteurExterne(
        theseId: these.id,
        nom: _nomController.text,
        prenom: _prenomController.text,
        universite: _universiteController.text,
        grade: _gradeController.text,
        pays: _paysController.text,
        email: _emailController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Demande envoyée avec succès !'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}