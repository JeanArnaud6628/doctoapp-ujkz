import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/these_provider.dart';
import '../../../providers/auth_provider.dart';

class CSIScreen extends ConsumerStatefulWidget {
  const CSIScreen({super.key});

  @override
  ConsumerState<CSIScreen> createState() => _CSIScreenState();
}

class _CSIScreenState extends ConsumerState<CSIScreen> {
  Map<String, dynamic>? _csiInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerCSI();
  }

  Future<void> _chargerCSI() async {
    final user = ref.read(authProvider).utilisateur;
    if (user == null) return;

    try {
      // Récupérer la thèse du doctorant
      final these = await Supabase.instance.client
          .from('theses')
          .select('id')
          .eq('doctorant_id', user.id)
          .maybeSingle();

      if (these != null) {
        // Récupérer les affectations CSI
        final affectations = await Supabase.instance.client
            .from('affectations_csi')
            .select('*, utilisateurs!csi_id(nom, prenom, grade, email, telephone)')
            .eq('these_id', these['id'])
            .eq('actif', true)
            .maybeSingle();

        if (affectations != null) {
          _csiInfo = affectations['utilisateurs'] as Map<String, dynamic>?;
        }
      }
    } catch (_) {}

    setState(() => _isLoading = false);
  }

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
        title: const Text('Mon CSI'),
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
          return _buildContenu(these);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildErrorState(
          'Impossible de charger votre thèse.',
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

  Widget _buildContenu(dynamic these) {
    final etape = these.etapeActuelle ?? 'enregistree';
    final aCSI = etape != 'enregistree' &&
        etape != 'directeur_choisi' &&
        etape != 'directeur_valide';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Message d'information ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: aCSI
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: aCSI ? AppTheme.primaryColor : AppTheme.orangeColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  aCSI ? Icons.check_circle : Icons.warning_amber_outlined,
                  color: aCSI ? AppTheme.primaryColor : AppTheme.orangeColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    aCSI
                        ? '✅ Un CSI vous a été affecté.'
                        : '⏳ En attente d\'affectation d\'un CSI.',
                    style: TextStyle(
                      fontSize: 12,
                      color: aCSI ? AppTheme.primaryColor : AppTheme.orangeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (aCSI && _csiInfo != null) ...[
            _buildCsiCard(),
            const SizedBox(height: 14),
            _buildRapportsSection(),
          ] else if (aCSI && _csiInfo == null) ...[
            _buildLoading(),
          ] else ...[
            _buildEnAttente(),
          ],
        ],
      ),
    );
  }

  Widget _buildCsiCard() {
    final csi = _csiInfo!;
    final nom = '${csi['prenom'] ?? ''} ${csi['nom'] ?? ''}';
    final grade = csi['grade'] as String? ?? 'Membre CSI';
    final email = csi['email'] as String? ?? 'Email non disponible';
    final telephone = csi['telephone'] as String? ?? 'Téléphone non disponible';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor, width: 1.5),
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
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                radius: 28,
                child: Text(
                  nom.isNotEmpty ? nom[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      grade,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          _buildContactRow(Icons.email, email),
          const SizedBox(height: 4),
          _buildContactRow(Icons.phone, telephone),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textGray),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textGray,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRapportsSection() {
    return Container(
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
            'SUIVI DES AVIS CSI',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF4A7A4A),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          // TODO: Afficher les avis CSI des rapports
          const Text(
            'Les avis du CSI apparaîtront ici.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEnAttente() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.pending, size: 48, color: Colors.orange),
          const SizedBox(height: 12),
          const Text(
            'En attente d\'affectation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'L\'administration vous affectera un CSI après validation de votre directeur.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM NAV ─────────────────────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context, int index) {
    return NavigationBar(
      selectedIndex: index,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE8F5E9),
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go(AppRoutes.dashboard);
            break;
          case 1:
            context.go(AppRoutes.these);
            break;
          case 2:
            context.go(AppRoutes.notifications);
            break;
          case 3:
            context.go(AppRoutes.opportunites);
            break;
          case 4:
            context.go(AppRoutes.profil);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppTheme.primaryColor),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description, color: AppTheme.primaryColor),
          label: 'Thèse',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications, color: AppTheme.primaryColor),
          label: 'Alertes',
        ),
        NavigationDestination(
          icon: Icon(Icons.lightbulb_outlined),
          selectedIcon: Icon(Icons.lightbulb, color: AppTheme.primaryColor),
          label: 'Opportunités',
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