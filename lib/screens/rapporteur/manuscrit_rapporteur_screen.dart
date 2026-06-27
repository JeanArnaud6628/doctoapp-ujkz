import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class ManuscritRapporteurScreen extends ConsumerStatefulWidget {
  final String expertiseId;
  const ManuscritRapporteurScreen({super.key, required this.expertiseId});

  @override
  ConsumerState<ManuscritRapporteurScreen> createState() =>
      _ManuscritRapporteurScreenState();
}

class _ManuscritRapporteurScreenState
    extends ConsumerState<ManuscritRapporteurScreen> {
  Map<String, dynamic>? _expertise;
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _manuscritUrl;

  @override
  void initState() {
    super.initState();
    _chargerExpertise();
  }

  Future<void> _chargerExpertise() async {
    try {
      final response = await Supabase.instance.client
          .from('rapports_expertise')
          .select(
          '''
              *,
              theses!these_id(
                id, 
                titre, 
                resume,
                mots_cles,
                doctorant_id,
                utilisateurs!doctorant_id(nom, prenom, ine)
              )
              ''')
          .eq('id', widget.expertiseId)
          .single();

      _expertise = response;
      _manuscritUrl = _expertise?['theses']?['manuscrit_url'] as String?;
    } catch (e) {
      print('Erreur chargement expertise: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _telechargerManuscrit() async {
    if (_manuscritUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manuscrit non disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      // 1. Mettre à jour le statut de l'expertise
      await Supabase.instance.client
          .from('rapports_expertise')
          .update({
        'statut': 'telecharge',
        'date_telechargement': DateTime.now().toIso8601String(),
      })
          .eq('id', widget.expertiseId);

      // 2. Démarrer le chronomètre (date limite +45 jours)
      final dateLimite = DateTime.now().add(const Duration(days: 45));
      await Supabase.instance.client
          .from('rapports_expertise')
          .update({
        'date_limite': dateLimite.toIso8601String().split('T')[0],
      })
          .eq('id', widget.expertiseId);

      // 3. Télécharger le manuscrit (TODO: lien de téléchargement réel)
      // Pour l'instant, on simule avec un message

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Manuscrit téléchargé ! Chronomètre démarré (45 jours)'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        context.go(AppRoutes.deposerRapportRapporteur);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.utilisateur;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_expertise == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manuscrit'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Expertise non trouvée'),
        ),
      );
    }

    final these = _expertise!['theses'] as Map<String, dynamic>?;
    final doctorant = these?['utilisateurs'] as Map<String, dynamic>?;
    final titre = these?['titre'] as String? ?? 'Sans titre';
    final resume = these?['resume'] as String? ?? '';
    final motsCles = these?['mots_cles'] as String? ?? '';
    final nomDoctorant = doctorant != null
        ? '${doctorant['prenom'] ?? ''} ${doctorant['nom'] ?? ''}'
        : 'Inconnu';

    final statut = _expertise!['statut'] as String? ?? 'en_attente';
    final dateLimite = _expertise!['date_limite'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Manuscrit à évaluer'),
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
                    'INFORMATIONS DE LA THÈSE',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4A7A4A),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow('Titre', titre),
                  _InfoRow('Doctorant', nomDoctorant),
                  if (motsCles.isNotEmpty)
                    _InfoRow('Mots-clés', motsCles),
                  if (resume.isNotEmpty)
                    _InfoRow('Résumé', resume),
                  if (dateLimite != null)
                    _InfoRow(
                      'Date limite',
                      DateFormat('dd/MM/yyyy').format(DateTime.parse(dateLimite)),
                    ),
                  _InfoRow(
                    'Statut',
                    _getStatutLibelle(statut),
                    color: _getStatutCouleur(statut),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Message de statut ─────────────────────────────────────
            _buildStatusMessage(statut),

            const SizedBox(height: 16),

            // ─── Action ─────────────────────────────────────────────────
            if (statut == 'en_attente')
              CustomButton(
                text: 'Télécharger le manuscrit',
                isLoading: _isDownloading,
                onPressed: _telechargerManuscrit,
              ),

            if (statut == 'telecharge')
              Column(
                children: [
                  CustomButton(
                    text: 'Déposer mon rapport',
                    onPressed: () {
                      context.go(AppRoutes.deposerRapportRapporteur);
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Télécharger à nouveau le manuscrit
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Télécharger à nouveau'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),

            if (statut == 'depose')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '✅ Rapport déposé avec succès',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (statut == 'retard')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '⚠️ Vous êtes en retard. Veuillez déposer votre rapport au plus vite.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Widget _buildStatusMessage(String statut) {
    String message;
    Color color;
    IconData icon;

    switch (statut) {
      case 'en_attente':
        message = '📄 Téléchargez le manuscrit pour commencer votre évaluation. Le chronomètre de 45 jours démarrera automatiquement.';
        color = AppTheme.primaryColor;
        icon = Icons.info_outline;
        break;
      case 'telecharge':
        message = '⏳ Vous avez téléchargé le manuscrit. Vous disposez de 45 jours pour déposer votre rapport.';
        color = Colors.blue;
        icon = Icons.timer;
        break;
      case 'depose':
        message = '✅ Votre rapport a été déposé avec succès. Merci pour votre contribution.';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'retard':
        message = '⚠️ Le délai de 45 jours est dépassé. Veuillez déposer votre rapport immédiatement.';
        color = Colors.red;
        icon = Icons.warning;
        break;
      default:
        message = 'Statut inconnu';
        color = Colors.grey;
        icon = Icons.help_outline;
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatutLibelle(String statut) {
    switch (statut) {
      case 'en_attente': return 'En attente de téléchargement';
      case 'telecharge': return 'Téléchargé - Évaluation en cours';
      case 'depose': return 'Déposé ✅';
      case 'retard': return 'En retard ❌';
      default: return statut;
    }
  }

  Color _getStatutCouleur(String statut) {
    switch (statut) {
      case 'en_attente': return Colors.orange;
      case 'telecharge': return Colors.blue;
      case 'depose': return Colors.green;
      case 'retard': return Colors.red;
      default: return Colors.grey;
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(
                fontSize: 11,
                color: color ?? AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}