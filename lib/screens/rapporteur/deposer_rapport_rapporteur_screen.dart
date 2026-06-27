import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class DeposerRapportRapporteurScreen extends ConsumerStatefulWidget {
  const DeposerRapportRapporteurScreen({super.key});

  @override
  ConsumerState<DeposerRapportRapporteurScreen> createState() =>
      _DeposerRapportRapporteurScreenState();
}

class _DeposerRapportRapporteurScreenState
    extends ConsumerState<DeposerRapportRapporteurScreen> {
  String? _selectedConclusion;
  File? _fichierSelectionne;
  String? _fichierNom;
  bool _isLoading = false;
  bool _isUploading = false;
  Map<String, dynamic>? _expertise;
  bool _isLoadingExpertise = true;

  final List<Map<String, dynamic>> _conclusions = [
    {'value': 'favorable', 'label': 'Favorable', 'color': Colors.green, 'icon': Icons.thumb_up},
    {'value': 'corrections_mineures', 'label': 'Corrections mineures', 'color': Colors.blue, 'icon': Icons.edit},
    {'value': 'corrections_majeures', 'label': 'Corrections majeures', 'color': Colors.orange, 'icon': Icons.warning},
    {'value': 'defavorable', 'label': 'Défavorable', 'color': Colors.red, 'icon': Icons.thumb_down},
  ];

  @override
  void initState() {
    super.initState();
    _chargerExpertise();
  }

  Future<void> _chargerExpertise() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('rapports_expertise')
          .select()
          .eq('rapporteur_id', user.id)
          .eq('statut', 'telecharge')
          .maybeSingle();

      _expertise = response;
    } catch (_) {}

    setState(() => _isLoadingExpertise = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.utilisateur;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoadingExpertise) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_expertise == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Déposer un rapport'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: AppTheme.textGray),
              SizedBox(height: 16),
              Text(
                'Aucune expertise en cours',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Vous n\'avez pas d\'expertise à traiter pour le moment.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGray,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.dashboardRapporteur),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text(
                  'Retour au tableau de bord',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Déposer mon rapport'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ─── Informations ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBDEFB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF0D47A1)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Déposez votre rapport d\'expertise pour la thèse "${_expertise?['these_id']}"',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0D47A1),
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
                    'Rapport d\'expertise',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Déposez votre rapport (PDF) et choisissez votre conclusion.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Upload fichier ──────────────────────────────────
                  const Text(
                    'Fichier du rapport *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _selectionnerFichier,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _fichierSelectionne != null
                              ? AppTheme.primaryColor
                              : const Color(0xFFC8DFC8),
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _fichierSelectionne != null
                            ? const Color(0xFFF0FBF0)
                            : const Color(0xFFF8FBF8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _fichierSelectionne != null
                                ? Icons.file_present
                                : Icons.upload_file,
                            color: _fichierSelectionne != null
                                ? AppTheme.primaryColor
                                : AppTheme.primaryColor,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _fichierSelectionne != null
                                ? _fichierNom ?? 'Fichier sélectionné'
                                : 'Sélectionner le fichier PDF',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _fichierSelectionne != null
                                  ? AppTheme.primaryColor
                                  : AppTheme.textDark,
                            ),
                          ),
                          Text(
                            _fichierSelectionne != null
                                ? 'Appuyez pour changer'
                                : 'PDF uniquement (max. 20 Mo)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textGray,
                            ),
                          ),
                          if (_fichierSelectionne != null) ...[
                            const SizedBox(height: 8),
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Conclusion ──────────────────────────────────────
                  const Text(
                    'Conclusion *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._conclusions.map((option) {
                    final isSelected = _selectedConclusion == option['value'];
                    final color = option['color'] as Color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedConclusion = option['value']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.08)
                              : const Color(0xFFF8FBF8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? color : const Color(0xFFE8EEE8),
                            width: isSelected ? 2 : 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              option['icon'] as IconData,
                              color: isSelected ? color : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                option['label'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected ? color : AppTheme.textDark,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: color,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // ─── Info ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBF0),
                      border: Border.all(color: const Color(0xFFFFE0A0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.orangeColor,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Une fois déposé, le rapport sera transmis à l\'administration pour validation.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF555555),
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
                    text: 'Déposer le rapport',
                    isLoading: _isLoading || _isUploading,
                    onPressed: _fichierSelectionne != null &&
                        _selectedConclusion != null
                        ? _deposer
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  // ─── MÉTHODES ──────────────────────────────────────────────────────────

  Future<void> _selectionnerFichier() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null) return;

      final file = File(result.files.single.path!);
      final size = await file.length();

      if (size > 20 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le fichier est trop volumineux (max 20 Mo)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _fichierSelectionne = file;
        _fichierNom = result.files.single.name;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _deposer() async {
    setState(() {
      _isLoading = true;
      _isUploading = true;
    });

    try {
      // TODO: Upload du fichier vers Supabase Storage
      // String? fichierUrl = await _uploadFichier(_fichierSelectionne!);
      await Future.delayed(const Duration(seconds: 2));

      // Mettre à jour l'expertise
      await Supabase.instance.client
          .from('rapports_expertise')
          .update({
        'statut': 'depose',
        'conclusion': _selectedConclusion,
        'date_depot': DateTime.now().toIso8601String(),
        // 'fichier_url': fichierUrl,
      })
          .eq('id', _expertise!['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Rapport déposé avec succès !'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        context.go(AppRoutes.dashboardRapporteur);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
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
            context.go(AppRoutes.dashboardRapporteur);
            break;
          case 1:
            context.go(AppRoutes.manuscritRapporteur);
            break;
          case 2:
            context.go(AppRoutes.profilRapporteur);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryColor),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.rate_review_outlined),
          selectedIcon: Icon(Icons.rate_review, color: AppTheme.primaryColor),
          label: 'Expertises',
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