import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class SignalementCSIScreen extends ConsumerStatefulWidget {
  final String? doctorantId;

  const SignalementCSIScreen({super.key, this.doctorantId});

  @override
  ConsumerState<SignalementCSIScreen> createState() =>
      _SignalementCSIScreenState();
}

class _SignalementCSIScreenState extends ConsumerState<SignalementCSIScreen> {
  final _descriptionController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isLoading = false;
  String? _selectedDoctorant;
  String? _selectedType;
  List<Map<String, dynamic>> _doctorants = [];

  final List<Map<String, String>> _typesSignalement = [
    {'value': 'conflit', 'label': 'Conflit avec le directeur'},
    {'value': 'blocage_academique', 'label': 'Blocage académique'},
    {'value': 'retard_rapport', 'label': 'Retard dans les rapports'},
    {'value': 'non_respect_engagement', 'label': 'Non-respect des engagements'},
    {'value': 'autre', 'label': 'Autre problème'},
  ];

  @override
  void initState() {
    super.initState();
    _chargerDoctorants();
    if (widget.doctorantId != null) {
      _selectedDoctorant = widget.doctorantId;
    }
  }

  Future<void> _chargerDoctorants() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final affectations = await Supabase.instance.client
          .from('affectations_csi')
          .select('*, utilisateurs!doctorant_id(nom, prenom, ine)')
          .eq('csi_id', user.id)
          .eq('actif', true);

      _doctorants = (affectations as List).map((a) {
        final u = a['utilisateurs'] as Map<String, dynamic>?;
        return {
          'id': a['doctorant_id'],
          'nom': u != null ? '${u['prenom'] ?? ''} ${u['nom'] ?? ''}' : 'Inconnu',
          'ine': u?['ine'] as String? ?? '',
        };
      }).toList();
    } catch (_) {}

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.utilisateur;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Signaler un problème'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              _showAideDialog();
            },
          ),
        ],
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
              const Text(
                'Signaler un problème',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Utilisez ce formulaire pour signaler un problème concernant un doctorant.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGray,
                ),
              ),
              const SizedBox(height: 16),

              // ─── Sélection doctorant ──────────────────────────────────
              if (widget.doctorantId == null) ...[
                const Text(
                  'Doctorant concerné *',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedDoctorant,
                  hint: const Text('Sélectionner un doctorant'),
                  items: _typesSignalement.map<DropdownMenuItem<String>>((t) {
                    return DropdownMenuItem<String>(
                      value: t['value'] as String,
                      child: Text(t['label'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedDoctorant = v),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FBF8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFC8DFC8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFC8DFC8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ─── Type de signalement ──────────────────────────────────
              const Text(
                'Type de problème *',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedType,
                hint: const Text('Sélectionner le type'),
                items: _typesSignalement.map((t) {
                  return DropdownMenuItem(
                    value: t['value'],
                    child: Text(t['label'] ?? ''),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedType = v),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FBF8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFC8DFC8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFC8DFC8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ─── Description ──────────────────────────────────────────
              const Text(
                'Description *',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _descriptionController,
                hintText: 'Décrivez brièvement le problème...',
                maxLines: 3,
              ),
              const SizedBox(height: 14),

              // ─── Détails ──────────────────────────────────────────────
              const Text(
                'Détails supplémentaires',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _detailsController,
                hintText: 'Informations complémentaires...',
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // ─── Info ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  border: Border.all(color: const Color(0xFFFFE0A0)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: AppTheme.orangeColor,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le signalement sera transmis à l\'administration pour traitement.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF555555),
                        ),
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
                      text: 'Envoyer le signalement',
                      isLoading: _isLoading,
                      onPressed: _selectedDoctorant != null &&
                          _selectedType != null &&
                          _descriptionController.text.isNotEmpty
                          ? _envoyerSignalement
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Future<void> _envoyerSignalement() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Enregistrer le signalement dans Supabase
      // await Supabase.instance.client.from('signalements').insert({
      //   'doctorant_id': _selectedDoctorant,
      //   'csi_id': Supabase.instance.client.auth.currentUser?.id,
      //   'type': _selectedType,
      //   'description': _descriptionController.text,
      //   'details': _detailsController.text,
      //   'statut': 'en_attente',
      // });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Signalement envoyé avec succès !'),
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

  void _showAideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('À propos des signalements'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous pouvez signaler :',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text('• Conflit avec le directeur de thèse'),
            Text('• Blocage académique'),
            Text('• Retard dans les rapports annuels'),
            Text('• Non-respect des engagements'),
            Text('• Tout autre problème'),
            SizedBox(height: 12),
            Text(
              'L\'administration traitera votre signalement dans les plus brefs délais.',
              style: TextStyle(fontSize: 12, color: AppTheme.textGray),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int index) {
    return NavigationBar(
      selectedIndex: index,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE8F5E9),
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go(AppRoutes.dashboardCSI);
            break;
          case 1:
            context.go(AppRoutes.rapportsCSI);
            break;
          case 2:
            context.go(AppRoutes.profilCSI);
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
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment, color: AppTheme.primaryColor),
          label: 'Rapports',
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