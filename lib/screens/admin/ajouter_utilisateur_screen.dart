import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AjouterUtilisateurScreen extends ConsumerStatefulWidget {
  final String role;
  const AjouterUtilisateurScreen({super.key, required this.role});

  @override
  ConsumerState<AjouterUtilisateurScreen> createState() =>
      _AjouterUtilisateurScreenState();
}

class _AjouterUtilisateurScreenState
    extends ConsumerState<AjouterUtilisateurScreen> {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telController = TextEditingController();
  final _ineController = TextEditingController();
  bool _isLoading = false;

  String get _titre {
    switch (widget.role) {
      case 'doctorant': return 'Ajouter un Doctorant';
      case 'directeur': return 'Ajouter un Directeur';
      case 'rapporteur': return 'Ajouter un Rapporteur';
      case 'csi': return 'Ajouter un Membre CSI';
      default: return 'Ajouter un Utilisateur';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_titre),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Informations personnelles',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark)),
              const SizedBox(height: 16),
              _buildLabel('Prénom *'),
              CustomTextField(
                controller: _prenomController,
                hintText: 'Prénom',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildLabel('Nom *'),
              CustomTextField(
                controller: _nomController,
                hintText: 'Nom de famille',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildLabel('Email *'),
              CustomTextField(
                controller: _emailController,
                hintText: 'adresse@email.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildLabel('Téléphone'),
              CustomTextField(
                controller: _telController,
                hintText: '+226 XX XX XX XX',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              if (widget.role == 'doctorant') ...[
                const SizedBox(height: 12),
                _buildLabel('INE *'),
                CustomTextField(
                  controller: _ineController,
                  hintText: 'Ex: BF2021XXXXXXXXX',
                  prefixIcon: Icons.badge_outlined,
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF0),
                  border: Border.all(
                      color: const Color(0xFFFFE0A0)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppTheme.orangeColor, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Un mot de passe temporaire "DoctoApp2026!" sera attribué. L\'utilisateur devra le modifier à sa première connexion.',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF555555)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Créer le compte',
                isLoading: _isLoading,
                onPressed: _creer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor)),
    );
  }

  Future<void> _creer() async {
    if (_nomController.text.isEmpty ||
        _prenomController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Remplissez les champs obligatoires')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(adminServiceProvider).creerUtilisateur(
        nom: _nomController.text,
        prenom: _prenomController.text,
        email: _emailController.text,
        role: widget.role,
        telephone: _telController.text.isEmpty
            ? null
            : _telController.text,
        ine: _ineController.text.isEmpty ? null : _ineController.text,
      );

      // Invalider le provider correspondant
      switch (widget.role) {
        case 'doctorant':
          ref.invalidate(doctorantsProvider);
          break;
        case 'directeur':
          ref.invalidate(directeursAdminProvider);
          break;
        case 'rapporteur':
          ref.invalidate(rapporteursAdminProvider);
          break;
        case 'csi':
          ref.invalidate(csiAdminProvider);
          break;
      }
      ref.invalidate(adminStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé avec succès !'),
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