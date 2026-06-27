import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../models/utilisateur_model.dart';
import '../../models/these_model.dart';
import '../../widgets/custom_button.dart';

class ProfilDoctorantAdminScreen extends ConsumerStatefulWidget {
  final String doctorantId;
  const ProfilDoctorantAdminScreen({
    super.key,
    required this.doctorantId,
  });

  @override
  ConsumerState<ProfilDoctorantAdminScreen> createState() =>
      _ProfilDoctorantAdminScreenState();
}

class _ProfilDoctorantAdminScreenState
    extends ConsumerState<ProfilDoctorantAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profilAsync = ref.watch(
      profilDoctorantProvider(widget.doctorantId),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: profilAsync.when(
        data: (data) {
          final u = UtilisateurModel.fromJson(
            data['utilisateur'] as Map<String, dynamic>,
          );
          final these = data['these'] as Map<String, dynamic>?;
          final rapports = (data['rapports'] as List?) ?? [];
          final manuscrit = data['manuscrit'] as Map<String, dynamic>?;
          final notifs = (data['notifications'] as List?) ?? [];
          final expertises = (data['expertises'] as List?) ?? [];
          final soutenances = (data['soutenances'] as List?) ?? [];
          final historique = (data['historique'] as List?) ?? [];

          return CustomScrollView(
            slivers: [
              _buildHeader(u, these),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildActions(u, these),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primaryColor,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Infos'),
                      Tab(text: 'Thèse'),
                      Tab(text: 'Rapports'),
                      Tab(text: 'Historique'),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(14),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 400,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _OngletInfos(u: u, ref: ref),
                          _OngletThese(
                            these: these,
                            rapports: rapports,
                            manuscrit: manuscrit,
                            ref: ref,
                          ),
                          _OngletRapports(
                            rapports: rapports,
                            expertises: expertises,
                            soutenances: soutenances,
                          ),
                          _OngletHistorique(
                            historique: historique,
                            notifs: notifs,
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text('Erreur: $e')),
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _buildHeader(UtilisateurModel u, Map<String, dynamic>? these) {
    final hasThese = these != null;
    final etape = hasThese ? these!['etape_actuelle'] as String? ?? 'enregistree' : 'enregistree';
    final statutLabel = hasThese ? _getEtapeLibelle(etape) : 'Aucune thèse';

    return SliverAppBar(
      expandedHeight: 190,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppTheme.primaryColor,
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Text(
                      u.initiales,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 24,
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
                          u.nomComplet,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'INE: ${u.ine ?? '–'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          u.ecoleDoctorale ?? 'UJKZ',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Statut: $statutLabel',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: u.estEnAttente
                          ? const Color(0xFFFF9800)
                          : u.estActif
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFF44336),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      u.estEnAttente
                          ? 'En attente'
                          : u.estActif
                          ? 'Actif'
                          : 'Inactif',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          color: Colors.white,
          onSelected: (value) async {
            switch (value) {
              case 'activer':
                await AdminService().activerDoctorant(u.ine ?? '');
                ref.invalidate(profilDoctorantProvider(widget.doctorantId));
                ref.invalidate(doctorantsProvider);
                ref.invalidate(statsDoctorantsProvider);
                ref.invalidate(cycleDoctoral);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Compte activé !'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                }
                break;
              case 'desactiver':
                await _showDesactiverDialog(u);
                break;
              case 'reactiver':
                await AdminService().reactiverDoctorant(u.id);
                ref.invalidate(profilDoctorantProvider(widget.doctorantId));
                ref.invalidate(doctorantsProvider);
                ref.invalidate(statsDoctorantsProvider);
                ref.invalidate(cycleDoctoral);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Compte réactivé !'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                }
                break;
              case 'supprimer':
                await _confirmSupprimer(u);
                break;

            // ─── NOUVELLES ACTIONS MÉTIER ───
              case 'valider_directeur':
                await _validerDirecteur(these);
                break;
              case 'affecter_csi':
                await _showAffecterCSIDialog(these?['id']);
                break;
              case 'valider_manuscrit':
                await _validerManuscritAdmin(these);
                break;
              case 'designer_rapporteurs':
                if (these != null) {
                  context.push(
                    '${AppRoutes.rapporteursMatching}/${these['id']}',
                  );
                }
                break;
            }
          },
          itemBuilder: (context) => [
            // ─── Gestion du compte ──────────────────────────────────────
            if (u.estEnAttente)
              const PopupMenuItem(
                value: 'activer',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Text('Activer le compte'),
                  ],
                ),
              ),
            if (u.estActif)
              const PopupMenuItem(
                value: 'desactiver',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Text('Désactiver le compte'),
                  ],
                ),
              ),
            if (u.estInactif && !u.estEnAttente)
              const PopupMenuItem(
                value: 'reactiver',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Text('Réactiver le compte'),
                  ],
                ),
              ),
            const PopupMenuDivider(),

            // ─── Actions métier ─────────────────────────────────────────
            if (these != null) ...[
              const PopupMenuItem(
                value: 'valider_directeur',
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Text('Valider le directeur'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'affecter_csi',
                child: Row(
                  children: [
                    Icon(Icons.group_add, color: Colors.teal, size: 18),
                    SizedBox(width: 8),
                    Text('Affecter un CSI'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'valider_manuscrit',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, color: Colors.purple, size: 18),
                    SizedBox(width: 8),
                    Text('Valider le manuscrit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'designer_rapporteurs',
                child: Row(
                  children: [
                    Icon(Icons.rate_review, color: Colors.indigo, size: 18),
                    SizedBox(width: 8),
                    Text('Désigner rapporteurs'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
            ],

            // ─── Suppression ────────────────────────────────────────────
            const PopupMenuItem(
              value: 'supprimer',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getEtapeLibelle(String etape) {
    switch (etape) {
      case 'enregistree': return 'Sujet enregistré';
      case 'directeur_choisi': return 'Directeur choisi';
      case 'directeur_valide': return 'Directeur validé';
      case 'csi_affecte': return 'CSI affecté';
      case 'rapport_annuel_1': return 'Rapport 1 en cours';
      case 'rapport_annuel_1_valide': return 'Rapport 1 validé';
      case 'rapport_annuel_2': return 'Rapport 2 en cours';
      case 'rapport_annuel_2_valide': return 'Rapport 2 validé';
      case 'rapport_annuel_3': return 'Rapport 3 en cours';
      case 'rapport_annuel_3_valide': return 'Rapport 3 validé';
      case 'manuscrit_depose': return 'Manuscrit déposé';
      case 'quitus_directeur': return 'Quitus Directeur';
      case 'quitus_csi': return 'Quitus CSI';
      case 'validation_admin': return 'Validation admin';
      case 'rapporteurs_affectes': return 'Rapporteurs affectés';
      case 'evaluation_rapporteurs': return 'Évaluation en cours';
      case 'soutenance_programmee': return 'Soutenance programmée';
      case 'soutenance_realisee': return '✅ Soutenance réalisée';
      default: return 'Sujet enregistré';
    }
  }

  // ─── ACTIONS ──────────────────────────────────────────────────────────────

  Widget _buildActions(UtilisateurModel u, Map<String, dynamic>? these) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ActionChip(
            icon: Icons.person_add,
            label: 'Affecter CSI',
            color: const Color(0xFF00695C),
            onTap: () {
              if (these != null) {
                _showAffecterCSIDialog(these['id']);
              }
            },
          ),
          _ActionChip(
            icon: Icons.rate_review,
            label: 'Désigner rapporteurs',
            color: const Color(0xFF6A1B9A),
            onTap: () {
              if (these != null) {
                context.push(
                  '${AppRoutes.rapporteursMatching}/${these['id']}',
                );
              }
            },
          ),
          _ActionChip(
            icon: Icons.event,
            label: 'Programmer soutenance',
            color: const Color(0xFFC62828),
            onTap: () {
              if (these != null) {
                _showProgrammerSoutenanceDialog(these['id']);
              }
            },
          ),
          _ActionChip(
            icon: Icons.send,
            label: 'Notifier',
            color: const Color(0xFFE65100),
            onTap: () {
              _showNotifierDialog(u.id);
            },
          ),
          _ActionChip(
            icon: Icons.verified,
            label: 'Valider directeur',
            color: Colors.blue,
            onTap: () {
              if (these != null) {
                _validerDirecteur(these);
              }
            },
          ),
        ],
      ),
    );
  }

  // ─── ACTIONS MÉTIER ─────────────────────────────────────────────────────

  Future<void> _validerDirecteur(Map<String, dynamic>? these) async {
    if (these == null) return;
    try {
      await AdminService().updateEtapeThese(these['id'], 'directeur_valide');
      ref.invalidate(profilDoctorantProvider(widget.doctorantId));
      ref.invalidate(cycleDoctoral);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Directeur validé avec succès !'),
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
    }
  }

  Future<void> _validerManuscritAdmin(Map<String, dynamic>? these) async {
    if (these == null) return;
    try {
      await AdminService().updateEtapeThese(these['id'], 'validation_admin');
      ref.invalidate(profilDoctorantProvider(widget.doctorantId));
      ref.invalidate(cycleDoctoral);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Manuscrit validé !'),
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
    }
  }

  // ─── DIALOGUE AFFECTATION CSI ──────────────────────────────────────────

  Future<void> _showAffecterCSIDialog(String? theseId) async {
    if (theseId == null) return;

    final csiList = await _getCSIDisponibles();

    if (csiList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun CSI disponible. Créez d\'abord un compte CSI.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    String? selectedCSI;
    bool isLoading = false;

    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            title: const Text('Affecter un CSI'),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sélectionnez un membre CSI :',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCSI,
                    hint: const Text('Choisir un CSI'),
                    items: csiList.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(c.nomComplet),
                      );
                    }).toList(),
                    onChanged: (v) => setModalState(() => selectedCSI = v),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: selectedCSI != null
                    ? () async {
                  setModalState(() => isLoading = true);
                  try {
                    await AdminService().affecterCSI(theseId, selectedCSI!);
                    ref.invalidate(profilDoctorantProvider(widget.doctorantId));
                    ref.invalidate(cycleDoctoral);
                    ref.invalidate(adminStatsProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ CSI affecté avec succès !'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    }
                    Navigator.pop(ctx);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  } finally {
                    setModalState(() => isLoading = false);
                  }
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Affecter', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<UtilisateurModel>> _getCSIDisponibles() async {
    try {
      final response = await Supabase.instance.client
          .from('utilisateurs')
          .select()
          .eq('role', 'csi')
          .eq('actif', true)
          .order('nom');
      return (response as List)
          .map((e) => UtilisateurModel.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _showProgrammerSoutenanceDialog(String theseId) {
    // TODO: Implémenter le dialogue de programmation soutenance
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de programmation soutenance en développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showNotifierDialog(String utilisateurId) {
    // TODO: Implémenter le dialogue de notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de notification en développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // ─── DIALOGUES COMPTE ────────────────────────────────────────────────────

  Future<void> _showDesactiverDialog(UtilisateurModel u) async {
    final motifController = TextEditingController();
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Désactiver le compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Motif de la désactivation :'),
            const SizedBox(height: 8),
            TextField(
              controller: motifController,
              decoration: const InputDecoration(
                hintText: 'Ex: Non-paiement des frais',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AdminService().desactiverDoctorant(
                u.id,
                motif: motifController.text.isNotEmpty
                    ? motifController.text
                    : null,
              );
              ref.invalidate(profilDoctorantProvider(widget.doctorantId));
              ref.invalidate(doctorantsProvider);
              ref.invalidate(statsDoctorantsProvider);
              ref.invalidate(cycleDoctoral);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Compte désactivé !'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSupprimer(UtilisateurModel u) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: Text(
          'Voulez-vous vraiment supprimer le compte de ${u.nomComplet} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AdminService().supprimerDoctorant(u.id);
              ref.invalidate(profilDoctorantProvider(widget.doctorantId));
              ref.invalidate(doctorantsProvider);
              ref.invalidate(statsDoctorantsProvider);
              ref.invalidate(cycleDoctoral);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Compte supprimé !'),
                    backgroundColor: Colors.red,
                  ),
                );
                context.pop();
                context.pop();
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTION CHIP
// ═══════════════════════════════════════════════════════════════════════════

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SLIVER TAB BAR DELEGATE
// ═══════════════════════════════════════════════════════════════════════════

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar child;

  _SliverTabBarDelegate({required this.child});

  @override
  double get minExtent => child.preferredSize.height;
  @override
  double get maxExtent => child.preferredSize.height;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return Container(
      color: Colors.white,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ONGLET 1 : INFORMATIONS
// ═══════════════════════════════════════════════════════════════════════════

class _OngletInfos extends StatelessWidget {
  final UtilisateurModel u;
  final WidgetRef ref;

  const _OngletInfos({required this.u, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _InfoCard(
            title: 'IDENTITÉ',
            children: [
              _InfoRow('Prénom', u.prenom),
              _InfoRow('Nom', u.nom),
              _InfoRow('INE', u.ine ?? '–'),
              _InfoRow('Sexe', u.sexe ?? '–'),
              _InfoRow('Date de naissance', u.dateNaissance ?? '–'),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'CONTACT',
            children: [
              _InfoRow('Email', u.email),
              _InfoRow('Téléphone', u.telephone ?? '–'),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'PARCOURS',
            children: [
              _InfoRow('École doctorale', u.ecoleDoctorale ?? '–'),
              _InfoRow('Formation', u.formationDoctorale ?? '–'),
              _InfoRow('Département', u.departement ?? '–'),
              _InfoRow('Laboratoire', u.laboratoire ?? '–'),
              _InfoRow('Promotion', u.promotion ?? '–'),
              _InfoRow('Année inscription', u.anneeInscription?.toString() ?? '–'),
              _InfoRow('Sujet provisoire', u.sujetProvisoire ?? '–'),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'STATUT DU COMPTE',
            children: [
              _InfoRow('Statut', u.statutLibelle),
              _InfoRow('Date activation', u.dateActivation ?? '–'),
              if (u.motifDesactivation != null)
                _InfoRow('Motif désactivation', u.motifDesactivation!),
              if (u.dateDesactivation != null)
                _InfoRow('Date désactivation', u.dateDesactivation!),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ONGLET 2 : THÈSE
// ═══════════════════════════════════════════════════════════════════════════

class _OngletThese extends StatelessWidget {
  final Map<String, dynamic>? these;
  final List rapports;
  final Map<String, dynamic>? manuscrit;
  final WidgetRef ref;

  const _OngletThese({
    required this.these,
    required this.rapports,
    required this.manuscrit,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    if (these == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune thèse enregistrée',
              style: TextStyle(fontSize: 16, color: AppTheme.textGray),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // TODO: Naviguer vers enregistrement thèse
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text(
                'Enregistrer une thèse',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _InfoCard(
            title: 'SUJET',
            children: [
              _InfoRow('Titre', these!['titre'] ?? '–'),
              _InfoRow('Spécialité', these!['specialite'] ?? '–'),
              _InfoRow('Mots-clés', these!['mots_cles'] ?? '–'),
              _InfoRow('Résumé', these!['resume'] ?? '–'),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'ÉTAT',
            children: [
              _InfoRow('État', these!['etat'] ?? '–'),
              _InfoRow('Étape actuelle', these!['etape_actuelle'] ?? '–'),
              _InfoRow('Année en cours', these!['annee_en_cours']?.toString() ?? '–'),
              _InfoRow('Date inscription', these!['date_inscription'] ?? '–'),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'QUITUS',
            children: [
              _InfoRow(
                'Quitus directeur',
                these!['quitus_directeur'] == true ? '✅ Oui' : '❌ Non',
                color: these!['quitus_directeur'] == true ? Colors.green : Colors.red,
              ),
              _InfoRow(
                'Quitus CSI',
                these!['quitus_csi'] == true ? '✅ Oui' : '❌ Non',
                color: these!['quitus_csi'] == true ? Colors.green : Colors.red,
              ),
              _InfoRow(
                'Validation admin',
                these!['validation_admin'] == true ? '✅ Oui' : '❌ Non',
                color: these!['validation_admin'] == true ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (manuscrit != null)
            _InfoCard(
              title: 'MANUSCRIT FINAL',
              children: [
                _InfoRow('Titre', manuscrit!['titre'] ?? '–'),
                _InfoRow('Statut', manuscrit!['statut'] ?? '–'),
                _InfoRow('Date dépôt', manuscrit!['date_depot'] ?? '–'),
              ],
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ONGLET 3 : RAPPORTS
// ═══════════════════════════════════════════════════════════════════════════

class _OngletRapports extends StatelessWidget {
  final List rapports;
  final List expertises;
  final List soutenances;

  const _OngletRapports({
    required this.rapports,
    required this.expertises,
    required this.soutenances,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _InfoCard(
            title: 'RAPPORTS ANNUELS (${rapports.length})',
            children: rapports.isEmpty
                ? [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Aucun rapport déposé',
                  style: TextStyle(color: AppTheme.textGray),
                ),
              ),
            ]
                : rapports.map((r) {
              return _InfoRow(
                'Année ${r['annee']}',
                r['statut'] ?? '–',
                color: r['statut'] == 'valide'
                    ? Colors.green
                    : r['statut'] == 'rejete'
                    ? Colors.red
                    : Colors.orange,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'RAPPORTS D\'EXPERTISE (${expertises.length})',
            children: expertises.isEmpty
                ? [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Aucun rapport d\'expertise',
                  style: TextStyle(color: AppTheme.textGray),
                ),
              ),
            ]
                : expertises.map((r) {
              return _InfoRow(
                'Rapporteur ID: ${r['rapporteur_id']?.substring(0, 8) ?? '–'}',
                r['statut'] ?? '–',
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'SOUTENANCES (${soutenances.length})',
            children: soutenances.isEmpty
                ? [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Aucune soutenance programmée',
                  style: TextStyle(color: AppTheme.textGray),
                ),
              ),
            ]
                : soutenances.map((s) {
              return _InfoRow(
                s['date_soutenance'] ?? '–',
                '${s['heure'] ?? ''} — ${s['lieu'] ?? ''}',
              );
            }).toList(),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ONGLET 4 : HISTORIQUE
// ═══════════════════════════════════════════════════════════════════════════

class _OngletHistorique extends StatelessWidget {
  final List historique;
  final List notifs;

  const _OngletHistorique({
    required this.historique,
    required this.notifs,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _InfoCard(
            title: 'HISTORIQUE DES ACTIONS (${historique.length})',
            children: historique.isEmpty
                ? [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Aucun historique',
                  style: TextStyle(color: AppTheme.textGray),
                ),
              ),
            ]
                : historique.map((h) {
              return _InfoRow(
                h['action'] ?? '–',
                h['created_at']?.substring(0, 16) ?? '–',
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'NOTIFICATIONS (${notifs.length})',
            children: notifs.isEmpty
                ? [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Aucune notification',
                  style: TextStyle(color: AppTheme.textGray),
                ),
              ),
            ]
                : notifs.map((n) {
              return _InfoRow(
                n['titre'] ?? '–',
                n['message'] ?? '–',
              );
            }).toList(),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS COMMUNS
// ═══════════════════════════════════════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF4A7A4A),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
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
            width: 100,
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