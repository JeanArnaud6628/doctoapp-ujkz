import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/these_provider.dart';
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
  int _anneeSelectionnee = DateTime.now().year;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Déposer un rapport'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rapport d\'avancement annuel',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 16),
                  const Text('Année *',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: _anneeSelectionnee,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FBF8),
                    ),
                    items: [1, 2, 3, 4, 5]
                        .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text('Année $a')))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _anneeSelectionnee = v!),
                  ),
                  const SizedBox(height: 14),
                  const Text('Titre du rapport *',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor)),
                  const SizedBox(height: 6),
                  CustomTextField(
                    controller: _titreController,
                    hintText: 'Ex: Rapport d\'avancement Année 2',
                    prefixIcon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 14),
                  // Zone upload
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppTheme.primaryColor,
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF8FCF8),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.upload_file,
                            color: AppTheme.primaryColor, size: 32),
                        const SizedBox(height: 8),
                        const Text('Déposer votre rapport',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const Text('PDF ou photo depuis votre appareil',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textGray)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.picture_as_pdf,
                                    size: 16),
                                label: const Text('PDF'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.camera_alt,
                                    size: 16),
                                label: const Text('Photo'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                  AppTheme.primaryColor,
                                  side: const BorderSide(
                                      color: AppTheme.primaryColor),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
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
              isLoading: _isLoading,
              onPressed: _soumettre,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _soumettre() async {
    if (_titreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez le titre')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await ref.read(theseServiceProvider).deposerRapport(
        doctorantId: user.id,
        annee: _anneeSelectionnee,
        titre: _titreController.text,
      );

      ref.invalidate(rapportsProvider(user.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rapport déposé avec succès !'),
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