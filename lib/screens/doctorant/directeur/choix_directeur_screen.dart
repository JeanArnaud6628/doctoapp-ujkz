import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/utilisateur_model.dart';
import '../../../providers/these_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/these_service.dart';
import '../../../models/these_model.dart';

class ChoixDirecteurScreen extends ConsumerStatefulWidget {
  const ChoixDirecteurScreen({super.key});

  @override
  ConsumerState<ChoixDirecteurScreen> createState() =>
      _ChoixDirecteurScreenState();
}

class _ChoixDirecteurScreenState extends ConsumerState<ChoixDirecteurScreen> {
  String? _directeurSelectionne;
  bool _isLoading = false;
  bool _demandeExterne = false;

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
        title: const Text('Choix du directeur'),
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
          return _buildContenu(user, these);
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

  Widget _buildContenu(UtilisateurModel user, TheseModel these) {
    // Vérifier si un directeur est déjà choisi
    final aDirecteur = these.directeurId != null;
    final etape = these.etapeActuelle ?? 'enregistree';
    final estValide = etape == 'directeur_valide' ||
        etape == 'csi_affecte' ||
        etape == 'rapport_annuel_1' ||
        etape == 'rapport_annuel_1_valide' ||
        etape == 'rapport_annuel_2' ||
        etape == 'rapport_annuel_2_valide' ||
        etape == 'rapport_annuel_3' ||
        etape == 'rapport_annuel_3_valide' ||
        etape == 'manuscrit_depose' ||
        etape == 'quitus_directeur' ||
        etape == 'quitus_csi' ||
        etape == 'validation_admin' ||
        etape == 'rapporteurs_affectes' ||
        etape == 'evaluation_rapporteurs' ||
        etape == 'soutenance_programmee' ||
        etape == 'soutenance_realisee';

    // Récupérer les directeurs de l'école du doctorant
    final ecole = user.ecoleDoctorale;
    final directeursAsync = ecole != null
        ? ref.watch(directeursByEcoleProvider(ecole))
        : ref.watch(directeursProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Message d'information ──────────────────────────────────────
          _buildInfoMessage(aDirecteur, estValide),

          const SizedBox(height: 14),

          if (aDirecteur && estValide) ...[
            // ─── Directeur déjà validé ────────────────────────────────────
            _buildDirecteurValide(these),
          ] else if (aDirecteur && !estValide) ...[
            // ─── Directeur choisi en attente de validation ──────────────
            _buildDirecteurEnAttente(these),
          ] else ...[
            // ─── Choix du directeur ──────────────────────────────────────
            _buildListeDirecteurs(directeursAsync, ecole),
          ],
        ],
      ),
    );
  }

  // ─── MESSAGE INFO ──────────────────────────────────────────────────────

  Widget _buildInfoMessage(bool aDirecteur, bool estValide) {
    String message;
    Color color;
    IconData icon;

    if (aDirecteur && estValide) {
      message = '✅ Votre directeur a été validé. Vous pouvez continuer.';
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (aDirecteur && !estValide) {
      message = '⏳ Votre demande de directeur est en attente de validation.';
      color = Colors.orange;
      icon = Icons.pending;
    } else {
      message =
      'Sélectionnez votre directeur de thèse parmi les professeurs de votre école doctorale.';
      color = AppTheme.primaryColor;
      icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── DIRECTEUR VALIDÉ ──────────────────────────────────────────────────

  Widget _buildDirecteurValide(TheseModel these) {
    return FutureBuilder(
      future: _getDirecteurInfo(these.directeurId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data;
        if (data == null) {
          return const Text('Directeur non trouvé');
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.15),
                child: Text(
                  data['prenom']?.substring(0, 1) ?? 'D',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data['prenom']} ${data['nom']}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (data['grade'] != null)
                      Text(
                        data['grade'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGray,
                        ),
                      ),
                    if (data['specialite'] != null)
                      Text(
                        data['specialite'],
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textGray,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        );
      },
    );
  }

  // ─── DIRECTEUR EN ATTENTE ─────────────────────────────────────────────

  Widget _buildDirecteurEnAttente(TheseModel these) {
    return FutureBuilder(
      future: _getDirecteurInfo(these.directeurId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data;
        if (data == null) {
          return const Text('Directeur non trouvé');
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orange.withOpacity(0.15),
                    child: Text(
                      data['prenom']?.substring(0, 1) ?? 'D',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${data['prenom']} ${data['nom']}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (data['grade'] != null)
                          Text(
                            data['grade'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textGray,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.pending, color: Colors.orange),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppTheme.orangeColor, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Votre demande est en attente de validation par l\'administration.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC84B00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── LISTE DES DIRECTEURS ─────────────────────────────────────────────

  Widget _buildListeDirecteurs(
      AsyncValue<List<Map<String, dynamic>>> directeursAsync,
      String? ecole,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Directeurs disponibles${ecole != null ? ' - $ecole' : ''}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez un directeur pour votre thèse.',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textGray,
          ),
        ),
        const SizedBox(height: 14),

        directeursAsync.when(
          data: (directeurs) {
            if (directeurs.isEmpty) {
              return _buildAucunDirecteur();
            }

            return Column(
              children: [
                ...directeurs.map((d) => _buildDirecteurCard(d)),
                const SizedBox(height: 14),
                _buildBoutonExterne(),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        ),
      ],
    );
  }

  Widget _buildAucunDirecteur() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0A0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_outlined,
              color: AppTheme.orangeColor, size: 32),
          const SizedBox(height: 10),
          const Text(
            'Aucun directeur disponible pour votre école doctorale.',
            style: TextStyle(fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Contactez l\'administration pour ajouter un directeur ou proposez un directeur externe.',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _buildBoutonExterne(),
        ],
      ),
    );
  }

  Widget _buildDirecteurCard(Map<String, dynamic> d) {
    final id = d['id'] as String;
    final nom = '${d['prenom']} ${d['nom']}';
    final grade = d['grade'] as String? ?? '';
    final specialite = d['specialite'] as String? ?? '';
    final selected = _directeurSelectionne == id;

    return GestureDetector(
      onTap: () => setState(() => _directeurSelectionne = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0FBF0) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : const Color(0xFFE0E0E0),
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
                nom.isNotEmpty ? nom[0].toUpperCase() : 'D',
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (grade.isNotEmpty || specialite.isNotEmpty)
                    Text(
                      '${grade.isNotEmpty ? grade : ''}${grade.isNotEmpty && specialite.isNotEmpty ? ' • ' : ''}${specialite.isNotEmpty ? specialite : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textGray,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: AppTheme.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBoutonExterne() {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: Ouvrir l'écran de demande de directeur externe
        // context.push(AppRoutes.directeurExterne);
      },
      icon: const Icon(Icons.person_add_outlined, size: 18),
      label: const Text('Proposer un directeur externe'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0D47A1),
        side: const BorderSide(color: Color(0xFF0D47A1)),
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ─── ACTIONS ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _getDirecteurInfo(String directeurId) async {
    try {
      final response = await Supabase.instance.client
          .from('utilisateurs')
          .select('nom, prenom, grade, specialite')
          .eq('id', directeurId)
          .single();
      return response;
    } catch (_) {
      return null;
    }
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