import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/these_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/these_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_textfield.dart';

class DeposerRapportScreen extends ConsumerStatefulWidget {
  const DeposerRapportScreen({super.key});

  @override
  ConsumerState<DeposerRapportScreen> createState() =>
      _DeposerRapportScreenState();
}

class _DeposerRapportScreenState
    extends ConsumerState<DeposerRapportScreen> {
  final _titreController = TextEditingController();
  int _anneeSelectionnee = 1;
  File? _fichierSelectionne;
  String? _fichierNom;
  bool _isLoading = false;
  bool _isUploading = false;

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
        title: const Text('Déposer un rapport'),
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
          'Impossible de charger votre thèse. Réessayez.',
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

  Widget _buildFormulaire(TheseModel these) {
    final etape = these.etapeActuelle ?? 'enregistree';

    // Vérifier si le doctorant peut déposer un rapport
    final peutDeposer = _peutDeposerRapport(etape);
    final message = _getMessage(etape);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Message d'information ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: peutDeposer
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: peutDeposer
                    ? AppTheme.primaryColor
                    : AppTheme.orangeColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  peutDeposer
                      ? Icons.check_circle
                      : Icons.warning_amber_outlined,
                  color: peutDeposer
                      ? AppTheme.primaryColor
                      : AppTheme.orangeColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      color: peutDeposer
                          ? AppTheme.primaryColor
                          : AppTheme.orangeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (peutDeposer) ...[
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
                    'Rapport d\'avancement annuel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Année ${_anneeSelectionnee}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Année ──────────────────────────────────────────────
                  const Text(
                    'Année *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: _anneeSelectionnee,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FBF8),
                    ),
                    items: [1, 2, 3, 4, 5]
                        .map((a) => DropdownMenuItem(
                      value: a,
                      child: Text('Année $a'),
                    ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _anneeSelectionnee = v!),
                  ),
                  const SizedBox(height: 14),

                  // ─── Titre ──────────────────────────────────────────────
                  const Text(
                    'Titre du rapport *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CustomTextField(
                    controller: _titreController,
                    hintText: 'Ex: Rapport d\'avancement Année 2',
                    prefixIcon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 14),

                  // ─── Upload fichier ─────────────────────────────────────
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
                                : 'Sélectionner un fichier',
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
                                : 'PDF ou photo (max. 20 Mo)',
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

                  // ─── Info supplémentaire ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBF0),
                      border: Border.all(color: const Color(0xFFFFE0A0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppTheme.orangeColor, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Le rapport sera soumis au directeur et au CSI pour validation.',
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
            CustomButton(
              text: 'Soumettre le rapport',
              isLoading: _isLoading || _isUploading,
              onPressed: _fichierSelectionne != null
                  ? _soumettre
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  // ─── MÉTHODES ─────────────────────────────────────────────────────────────

  bool _peutDeposerRapport(String etape) {
    // Un doctorant peut déposer un rapport si :
    // - Il a un directeur validé
    // - Il a un CSI affecté
    // - L'étape actuelle est un rapport annuel ou après
    final etapesRapport = [
      'rapport_annuel_1',
      'rapport_annuel_1_valide',
      'rapport_annuel_2',
      'rapport_annuel_2_valide',
      'rapport_annuel_3',
      'rapport_annuel_3_valide',
    ];
    return etapesRapport.contains(etape) || etape == 'csi_affecte';
  }

  String _getMessage(String etape) {
    if (_peutDeposerRapport(etape)) {
      return '✅ Vous pouvez déposer votre rapport annuel.';
    }
    switch (etape) {
      case 'enregistree':
        return '⏳ En attente de validation du directeur.';
      case 'directeur_choisi':
        return '⏳ En attente de validation du directeur.';
      case 'directeur_valide':
        return '⏳ En attente d\'affectation du CSI.';
      default:
        return '⏳ Le dépôt de rapport n\'est pas encore disponible.';
    }
  }

  Future<void> _selectionnerFichier() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null) return;

      final file = File(result.files.single.path!);
      final size = await file.length();

      // Vérifier la taille (max 20 Mo)
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

  Future<void> _soumettre() async {
    if (_titreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez le titre')),
      );
      return;
    }

    if (_fichierSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un fichier')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // TODO: Upload du fichier vers Supabase Storage
      // String? fichierUrl = await _uploadFichier(_fichierSelectionne!, user.id);
      // Pour l'instant, on simule l'upload

      // Simuler un délai d'upload
      await Future.delayed(const Duration(seconds: 2));

      await ref.read(theseServiceProvider).deposerRapport(
        doctorantId: user.id,
        annee: _anneeSelectionnee,
        titre: _titreController.text,
        // fichierPdf: fichierUrl,
      );

      ref.invalidate(rapportsProvider(user.id));
      ref.invalidate(theseProvider(user.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Rapport déposé avec succès !'),
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
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }

  // ─── UPLOAD FICHIER ──────────────────────────────────────────────────────

  Future<String?> _uploadFichier(File fichier, String userId) async {
    try {
      final fileName = path.basename(fichier.path);
      final filePath = 'rapports/$userId/$fileName';

      // Upload vers Supabase Storage
      // final response = await Supabase.instance.client.storage
      //     .from('rapports')
      //     .upload(filePath, fichier.readAsBytesSync());

      // return response;
      return null;
    } catch (e) {
      throw Exception('Erreur lors de l\'upload: $e');
    }
  }
}