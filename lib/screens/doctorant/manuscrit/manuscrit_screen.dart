import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/these_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/these_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_textfield.dart';

class ManuscritScreen extends ConsumerStatefulWidget {
  const ManuscritScreen({super.key});

  @override
  ConsumerState<ManuscritScreen> createState() => _ManuscritScreenState();
}

class _ManuscritScreenState extends ConsumerState<ManuscritScreen> {
  final _titreController = TextEditingController();
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
    final manuscritAsync = ref.watch(manuscritProvider(user.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Manuscrit final'),
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
          return manuscritAsync.when(
            data: (manuscrit) => manuscrit != null
                ? _buildManuscritExistant(manuscrit, these)
                : _buildDeposerManuscrit(these),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildDeposerManuscrit(these),
          );
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

  Widget _buildManuscritExistant(dynamic manuscrit, TheseModel these) {
    final isValide = manuscrit.statut == 'valide';
    final isAttente = manuscrit.statut == 'en attente';
    final isRejete = manuscrit.statut == 'rejete';

    Color statutColor;
    String statutLabel;
    String statutIcon;

    if (isValide) {
      statutColor = Colors.green;
      statutLabel = '✅ Validé';
      statutIcon = '✅';
    } else if (isAttente) {
      statutColor = Colors.orange;
      statutLabel = '⏳ En attente de validation';
      statutIcon = '⏳';
    } else if (isRejete) {
      statutColor = Colors.red;
      statutLabel = '❌ Rejeté';
      statutIcon = '❌';
    } else {
      statutColor = Colors.grey;
      statutLabel = 'Statut inconnu';
      statutIcon = '❓';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: statutColor,
                width: isValide ? 1.5 : 0.5,
              ),
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
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statutColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          statutIcon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manuscrit final',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textGray,
                            ),
                          ),
                          Text(
                            statutLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: statutColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _buildInfoRow('Titre', manuscrit.titre),
                _buildInfoRow('Date dépôt', manuscrit.dateDepot),
                if (isRejete)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Votre manuscrit a été rejeté. Vous pouvez le modifier et le redéposer.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if (isRejete || isAttente)
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Télécharger le manuscrit
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Télécharger le manuscrit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                if (isRejete)
                  const SizedBox(height: 8),
                if (isRejete)
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Redéposer un manuscrit
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Redéposer le manuscrit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Progression
          Container(
            padding: const EdgeInsets.all(14),
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
                  'PROGRESSION GLOBALE',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4A7A4A),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Avancement',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                    ),
                    Text(
                      '${these.progression}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: these.progression / 100,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeposerManuscrit(TheseModel these) {
    final peutDeposer = _peutDeposerManuscrit(these);

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
                    peutDeposer
                        ? '✅ Vous pouvez déposer votre manuscrit final.'
                        : '⏳ Les 3 rapports annuels doivent être validés avant le dépôt.',
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
                    'Dépôt du manuscrit final',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Déposez la version finale de votre thèse.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Titre ──────────────────────────────────────────────
                  const Text(
                    'Titre du manuscrit *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CustomTextField(
                    controller: _titreController,
                    hintText: 'Titre complet de votre thèse',
                    prefixIcon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 14),

                  // ─── Upload fichier ─────────────────────────────────────
                  const Text(
                    'Fichier manuscrit (PDF) *',
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
                                : 'PDF uniquement (max. 100 Mo)',
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
                            'Une fois déposé, le directeur de thèse et le CSI doivent donner leur quitus avant validation.',
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
              text: 'Déposer le manuscrit final',
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

  bool _peutDeposerManuscrit(TheseModel these) {
    // Vérifier que les 3 rapports sont validés
    // Pour simplifier, on vérifie l'étape actuelle
    final etape = these.etapeActuelle ?? 'enregistree';
    final etapesManuscrit = [
      'manuscrit_depose',
      'quitus_directeur',
      'quitus_csi',
      'validation_admin',
      'rapporteurs_affectes',
      'evaluation_rapporteurs',
      'soutenance_programmee',
      'soutenance_realisee',
    ];
    return etapesManuscrit.contains(etape) ||
        etape == 'rapport_annuel_3_valide';
  }

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

      if (size > 100 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le fichier est trop volumineux (max 100 Mo)'),
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

      // TODO: Upload vers Supabase Storage
      await Future.delayed(const Duration(seconds: 2));

      await ref.read(theseServiceProvider).deposerManuscrit(
        doctorantId: user.id,
        titre: _titreController.text,
        // fichierPdf: fichierUrl,
      );

      ref.invalidate(manuscritProvider(user.id));
      ref.invalidate(theseProvider(user.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Manuscrit déposé avec succès !'),
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
}