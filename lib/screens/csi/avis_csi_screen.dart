import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AvisCSIScreen extends ConsumerStatefulWidget {
  final String? rapportId;
  final String? doctorantId;

  const AvisCSIScreen({super.key, this.rapportId, this.doctorantId});

  @override
  ConsumerState<AvisCSIScreen> createState() => _AvisCSIScreenState();
}

class _AvisCSIScreenState extends ConsumerState<AvisCSIScreen> {
  String? _selectedAvis;
  final _commentaireController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _rapport;
  bool _isLoadingRapport = true;

  final List<Map<String, dynamic>> _optionsAvis = [
    {'value': 'favorable', 'label': 'Favorable', 'color': Colors.green, 'icon': Icons.thumb_up},
    {'value': 'defavorable', 'label': 'Défavorable', 'color': Colors.red, 'icon': Icons.thumb_down},
    {'value': 'signalement', 'label': 'Signalement', 'color': Colors.orange, 'icon': Icons.warning},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.rapportId != null) {
      _chargerRapport();
    }
  }

  Future<void> _chargerRapport() async {
    try {
      final response = await Supabase.instance.client
          .from('rapports_avancement')
          .select('*, utilisateurs!doctorant_id(nom, prenom, ine)')
          .eq('id', widget.rapportId!)
          .single();

      _rapport = response;
    } catch (_) {}

    setState(() => _isLoadingRapport = false);
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
        title: const Text('Donner mon avis'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingRapport
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
              // ─── Informations du rapport ──────────────────────
              if (_rapport != null) ...[
                const Text(
                  'RAPPORT',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4A7A4A),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _rapport!['titre'] as String? ?? 'Rapport Année ${_rapport!['annee']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Année ${_rapport!['annee']} • Déposé le ${_rapport!['date_depot'] ?? '–'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 14),
              ],

              const Text(
                'Choisissez votre avis *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cet avis sera visible par le doctorant et l\'administration.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGray,
                ),
              ),
              const SizedBox(height: 16),

              // ─── Options d'avis ──────────────────────────────────
              ..._optionsAvis.map((option) {
                final isSelected = _selectedAvis == option['value'];
                final color = option['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAvis = option['value']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.08)
                          : const Color(0xFFF8FBF8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : const Color(0xFFE8EEE8),
                        width: isSelected ? 2 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option['icon'] as IconData,
                          color: isSelected ? color : Colors.grey,
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

              // ─── Commentaire ──────────────────────────────────────
              const Text(
                'Commentaire',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _commentaireController,
                hintText: 'Ajoutez un commentaire...',
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // ─── Info ────────────────────────────────────────────
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
                        'Un avis "Signalement" déclenche une alerte auprès de l\'administration.',
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

              CustomButton(
                text: 'Soumettre mon avis',
                isLoading: _isLoading,
                onPressed: _selectedAvis != null
                    ? _soumettreAvis
                    : null,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Future<void> _soumettreAvis() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Mettre à jour l'avis CSI dans le rapport
      // await Supabase.instance.client
      //     .from('rapports_avancement')
      //     .update({
      //       'avis_csi': _selectedAvis,
      //       'avis_csi_date': DateTime.now().toIso8601String(),
      //       'commentaire_csi': _commentaireController.text,
      //     })
      //     .eq('id', widget.rapportId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Avis soumis avec succès !'),
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