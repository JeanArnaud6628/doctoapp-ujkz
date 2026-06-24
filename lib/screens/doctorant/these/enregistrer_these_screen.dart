import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/these_provider.dart';
import '../../../services/these_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_textfield.dart';

class EnregistrerTheseScreen extends ConsumerStatefulWidget {
  const EnregistrerTheseScreen({super.key});

  @override
  ConsumerState<EnregistrerTheseScreen> createState() =>
      _EnregistrerTheseScreenState();
}

class _EnregistrerTheseScreenState
    extends ConsumerState<EnregistrerTheseScreen> {
  final _titreController = TextEditingController();
  final _specialiteController = TextEditingController();
  final _resumeController = TextEditingController();
  final _motsClesController = TextEditingController();
  String? _directeurSelectionne;
  int _etape = 1;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: _etape == 1
                    ? _buildEtape1()
                    : _etape == 2
                    ? _buildEtape2()
                    : _buildEtape3(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final titles = [
      'Étape 1 sur 3 – Informations',
      'Étape 2 sur 3 – Directeur',
      'Étape 3 sur 3 – Confirmation',
    ];
    return Container(
      color: AppTheme.primaryColor,
      padding: const EdgeInsets.only(
          top: 50, bottom: 36, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (_etape > 1) {
                setState(() => _etape--);
              } else {
                context.pop();
              }
            },
            child: const Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.white70, size: 18),
                SizedBox(width: 6),
                Text('Retour',
                    style:
                    TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Enregistrer mon projet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(titles[_etape - 1],
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  height: 4,
                  decoration: BoxDecoration(
                    color: index < _etape
                        ? Colors.white
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEtape1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informations de recherche',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark)),
        const SizedBox(height: 20),
        _buildLabel('Titre de la thèse *'),
        CustomTextField(
          controller: _titreController,
          hintText: 'Ex: Optimisation des systèmes solaires...',
          prefixIcon: Icons.edit_outlined,
        ),
        const SizedBox(height: 14),
        _buildLabel('Spécialité *'),
        CustomTextField(
          controller: _specialiteController,
          hintText: 'Ex: Physique, Informatique, Chimie...',
          prefixIcon: Icons.science_outlined,
        ),
        const SizedBox(height: 14),
        _buildLabel('Résumé (300 mots max.) *'),
        CustomTextField(
          controller: _resumeController,
          hintText: 'Décrivez brièvement votre projet...',
          maxLines: 4,
        ),
        const SizedBox(height: 14),
        _buildLabel('Mots-clés'),
        CustomTextField(
          controller: _motsClesController,
          hintText: 'Ex: énergie solaire, Sahel, photovoltaïque',
          prefixIcon: Icons.tag,
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Suivant →',
          onPressed: () {
            if (_titreController.text.isEmpty ||
                _specialiteController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Remplissez les champs obligatoires')),
              );
              return;
            }
            setState(() => _etape = 2);
          },
        ),
      ],
    );
  }

  Widget _buildEtape2() {
    final directeursAsync = ref.watch(directeursProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Votre directeur de thèse',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark)),
        const SizedBox(height: 6),
        const Text(
          'Sélectionnez votre directeur dans l\'annuaire UJKZ',
          style: TextStyle(fontSize: 12, color: AppTheme.textGray),
        ),
        const SizedBox(height: 20),
        directeursAsync.when(
          data: (directeurs) => directeurs.isEmpty
              ? Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFFE0A0)),
            ),
            child: const Text(
              'Aucun directeur disponible pour l\'instant. Contactez l\'administration.',
              style: TextStyle(fontSize: 12),
            ),
          )
              : Column(
            children: directeurs.map((d) {
              final id = d['id'] as String;
              final nom = '${d['prenom']} ${d['nom']}';
              final selected = _directeurSelectionne == id;
              return GestureDetector(
                onTap: () =>
                    setState(() => _directeurSelectionne = id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFF0FBF0)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primaryColor
                          : const Color(0xFFE0E0E0),
                      width: selected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: selected
                            ? AppTheme.primaryColor
                            : const Color(0xFFE0E0E0),
                        child: Text(
                          nom.isNotEmpty
                              ? nom[0].toUpperCase()
                              : 'D',
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(nom,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight:
                                FontWeight.w500)),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle,
                            color: AppTheme.primaryColor,
                            size: 20),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Erreur: $e'),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _etape = 1),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('← Retour'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Suivant →',
                onPressed: () => setState(() => _etape = 3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEtape3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Confirmation',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark)),
        const SizedBox(height: 6),
        const Text('Vérifiez vos informations avant d\'enregistrer',
            style: TextStyle(fontSize: 12, color: AppTheme.textGray)),
        const SizedBox(height: 20),
        _buildConfirmItem('Titre', _titreController.text),
        _buildConfirmItem('Spécialité', _specialiteController.text),
        _buildConfirmItem(
            'Résumé',
            _resumeController.text.isEmpty
                ? 'Non renseigné'
                : _resumeController.text),
        _buildConfirmItem(
            'Mots-clés',
            _motsClesController.text.isEmpty
                ? 'Non renseignés'
                : _motsClesController.text),
        _buildConfirmItem(
            'Directeur',
            _directeurSelectionne != null
                ? 'Sélectionné'
                : 'Non sélectionné'),
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
              Icon(Icons.info_outline, color: Color(0xFF0D47A1), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ces informations seront utilisées pour désigner vos rapporteurs lors du dépôt du manuscrit final.',
                  style:
                  TextStyle(fontSize: 11, color: Color(0xFF0D47A1)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _etape = 2),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('← Retour'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Enregistrer mon projet',
                isLoading: _isLoading,
                onPressed: _enregistrer,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGray,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textDark)),
          ),
        ],
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

  Future<void> _enregistrer() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await ref.read(theseServiceProvider).enregistrerThese(
        doctorantId: user.id,
        titre: _titreController.text,
        specialite: _specialiteController.text,
        resume: _resumeController.text,
        motsCles: _motsClesController.text,
        directeurId: _directeurSelectionne,
      );

      ref.invalidate(theseProvider(user.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Projet enregistré avec succès !'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        context.go(AppRoutes.dashboard);
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