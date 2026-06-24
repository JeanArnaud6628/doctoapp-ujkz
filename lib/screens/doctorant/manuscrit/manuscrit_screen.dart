import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/these_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_textfield.dart';

class ManuscritScreen extends ConsumerStatefulWidget {
  const ManuscritScreen({super.key});

  @override
  ConsumerState<ManuscritScreen> createState() => _ManuscritScreenState();
}

class _ManuscritScreenState extends ConsumerState<ManuscritScreen> {
  final _titreController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const Scaffold();

    final manuscritAsync = ref.watch(manuscritProvider(user.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Manuscrit final'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: manuscritAsync.when(
        data: (manuscrit) => manuscrit != null
            ? _buildManuscritExistant(manuscrit)
            : _buildDeposerManuscrit(context, user.id),
        loading: () =>
        const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildDeposerManuscrit(
            context, user?.id ?? ''),
      ),
    );
  }

  Widget _buildManuscritExistant(dynamic manuscrit) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.primaryColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle,
                    color: AppTheme.primaryColor, size: 20),
                SizedBox(width: 8),
                Text('Manuscrit déposé',
                    style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            Text(manuscrit.titre,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Déposé le ${manuscrit.dateDepot}',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textGray)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                manuscrit.statut == 'valide'
                    ? 'Validé par le Directeur'
                    : 'En attente de validation',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFFC84B00)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeposerManuscrit(BuildContext context, String userId) {
    return SingleChildScrollView(
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
                const Text('Dépôt du manuscrit final',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark)),
                const SizedBox(height: 6),
                const Text(
                  'Déposez la version finale de votre thèse. Le directeur devra la valider avant instruction.',
                  style:
                  TextStyle(fontSize: 12, color: AppTheme.textGray),
                ),
                const SizedBox(height: 16),
                const Text('Titre du manuscrit *',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor)),
                const SizedBox(height: 6),
                CustomTextField(
                  controller: _titreController,
                  hintText: 'Titre complet de votre thèse',
                  prefixIcon: Icons.description_outlined,
                ),
                const SizedBox(height: 16),
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
                      const Text('Fichier manuscrit (PDF)',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const Text('Taille max. 100 Mo',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textGray)),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.upload, size: 16),
                        label: const Text('Choisir le fichier'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF0),
              border: Border.all(color: const Color(0xFFFFE0A0)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_outlined,
                    color: AppTheme.orangeColor, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Une fois déposé, le directeur de thèse doit valider ce manuscrit avant qu\'il soit envoyé aux rapporteurs.',
                    style:
                    TextStyle(fontSize: 11, color: Color(0xFF555555)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Déposer le manuscrit final',
            isLoading: _isLoading,
            onPressed: () => _deposer(userId),
          ),
        ],
      ),
    );
  }

  Future<void> _deposer(String userId) async {
    if (_titreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez le titre')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(theseServiceProvider).deposerManuscrit(
        doctorantId: userId,
        titre: _titreController.text,
      );
      ref.invalidate(manuscritProvider(userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manuscrit déposé avec succès !'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
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