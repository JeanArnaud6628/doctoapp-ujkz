import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class EntretienCSIScreen extends ConsumerStatefulWidget {
  final String? doctorantId;

  const EntretienCSIScreen({super.key, this.doctorantId});

  @override
  ConsumerState<EntretienCSIScreen> createState() => _EntretienCSIScreenState();
}

class _EntretienCSIScreenState extends ConsumerState<EntretienCSIScreen> {
  final _compteRenduController = TextEditingController();
  final _dateController = TextEditingController();
  final _remarquesController = TextEditingController();
  bool _isLoading = false;
  String? _selectedDoctorant;
  List<Map<String, dynamic>> _doctorants = [];

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
        title: const Text('Enregistrer un entretien'),
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
              const Text(
                'Entretien annuel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enregistrez le compte-rendu de votre entretien avec le doctorant.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGray,
                ),
              ),
              const SizedBox(height: 16),

              // ─── Sélection doctorant ──────────────────────────────────
              if (widget.doctorantId == null) ...[
                const Text(
                  'Doctorant *',
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
                  items: _doctorants.map<DropdownMenuItem<String>>((d) {
                    return DropdownMenuItem<String>(
                      value: d['id'] as String,
                      child: Text('${d['nom']} (${d['ine']})'),
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

              // ─── Date ──────────────────────────────────────────────────
              const Text(
                'Date de l\'entretien *',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _dateController,
                hintText: 'YYYY-MM-DD',
                prefixIcon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 14),

              // ─── Compte rendu ──────────────────────────────────────────
              const Text(
                'Compte-rendu *',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _compteRenduController,
                hintText: 'Résumé de l\'entretien...',
                maxLines: 5,
              ),
              const SizedBox(height: 14),

              // ─── Remarques ─────────────────────────────────────────────
              const Text(
                'Remarques supplémentaires',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _remarquesController,
                hintText: 'Observations, points à suivre...',
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // ─── Info ──────────────────────────────────────────────────
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
                        'L\'entretien sera enregistré et visible par l\'administration et le doctorant.',
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
                text: 'Enregistrer l\'entretien',
                isLoading: _isLoading,
                onPressed: _selectedDoctorant != null
                    ? _enregistrer
                    : null,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Future<void> _enregistrer() async {
    if (_dateController.text.isEmpty || _compteRenduController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remplissez tous les champs obligatoires'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Enregistrer l'entretien dans Supabase
      // await Supabase.instance.client.from('entretiens_csi').insert({
      //   'doctorant_id': _selectedDoctorant,
      //   'csi_id': Supabase.instance.client.auth.currentUser?.id,
      //   'date_entretien': _dateController.text,
      //   'compte_rendu': _compteRenduController.text,
      //   'remarques': _remarquesController.text,
      // });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Entretien enregistré avec succès !'),
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