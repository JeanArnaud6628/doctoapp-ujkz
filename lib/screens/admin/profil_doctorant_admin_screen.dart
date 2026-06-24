import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../services/admin_service.dart';
import '../../models/utilisateur_model.dart';

final profilDoctorantProvider =
FutureProvider.family<Map<String, dynamic>, String>(
        (ref, doctorantId) async {
      return AdminService().getProfilCompletDoctorant(doctorantId);
    });

class ProfilDoctorantAdminScreen extends ConsumerWidget {
  final String doctorantId;
  const ProfilDoctorantAdminScreen(
      {super.key, required this.doctorantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilAsync = ref.watch(profilDoctorantProvider(doctorantId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: profilAsync.when(
        data: (data) {
          final u = UtilisateurModel.fromJson(
              data['utilisateur'] as Map<String, dynamic>);
          final these = data['these'] as Map<String, dynamic>?;
          final rapports = (data['rapports'] as List?) ?? [];
          final manuscrit = data['manuscrit'] as Map<String, dynamic>?;
          final notifs = (data['notifications'] as List?) ?? [];
          final rapportsExpertise =
              (data['rapports_expertise'] as List?) ?? [];
          final soutenances = (data['soutenances'] as List?) ?? [];

          return CustomScrollView(
            slivers: [
              _buildHeader(context, u, ref),
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Infos personnelles
                    _buildSection(
                      'INFORMATIONS PERSONNELLES',
                      [
                        _buildInfoRow('INE', u.ine ?? '–'),
                        _buildInfoRow('Email', u.email),
                        _buildInfoRow('Téléphone',
                            u.telephone ?? '–'),
                        _buildInfoRow('École doctorale',
                            u.ecoleDoctorale ?? '–'),
                        _buildInfoRow('Statut',
                            u.actif ? 'Actif ✓' : 'Désactivé ✗'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Sujet de thèse
                    these != null
                        ? _buildSection(
                      'SUJET DE THÈSE',
                      [
                        _buildInfoRow(
                            'Titre', these['titre'] ?? '–'),
                        _buildInfoRow('Spécialité',
                            these['specialite'] ?? '–'),
                        _buildInfoRow(
                            'Mots-clés',
                            these['mots_cles'] ?? '–'),
                        _buildInfoRow(
                            'État', these['etat'] ?? '–'),
                        _buildInfoRow(
                            'Date inscription',
                            these['date_inscription'] ?? '–'),
                      ],
                    )
                        : _buildEmptyCard(
                        'Aucune thèse enregistrée',
                        Icons.description_outlined),
                    const SizedBox(height: 10),
                    // Rapports annuels
                    _buildSection(
                      'RAPPORTS ANNUELS (${rapports.length})',
                      rapports.isEmpty
                          ? [_buildInfoRow('', 'Aucun rapport déposé')]
                          : rapports
                          .map<Widget>((r) => _buildInfoRow(
                        'Année ${r['annee']}',
                        r['statut'] ?? '–',
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    // Manuscrit
                    manuscrit != null
                        ? _buildSection(
                      'MANUSCRIT FINAL',
                      [
                        _buildInfoRow(
                            'Titre', manuscrit['titre'] ?? '–'),
                        _buildInfoRow('Date dépôt',
                            manuscrit['date_depot'] ?? '–'),
                        _buildInfoRow(
                            'Statut', manuscrit['statut'] ?? '–'),
                      ],
                    )
                        : _buildEmptyCard(
                        'Aucun manuscrit déposé',
                        Icons.upload_file_outlined),
                    const SizedBox(height: 10),
                    // Rapporteurs
                    _buildSection(
                      'RAPPORTEURS (${rapportsExpertise.length})',
                      rapportsExpertise.isEmpty
                          ? [_buildInfoRow('', 'Aucun rapporteur désigné')]
                          : rapportsExpertise
                          .map<Widget>((r) => _buildInfoRow(
                        'Date limite',
                        r['date_limite'] ?? '–',
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    // Soutenance
                    soutenances.isNotEmpty
                        ? _buildSection(
                      'SOUTENANCE',
                      [
                        _buildInfoRow('Date',
                            soutenances[0]['date_soutenance'] ?? '–'),
                        _buildInfoRow(
                            'Lieu', soutenances[0]['lieu'] ?? '–'),
                        _buildInfoRow(
                            'Président',
                            soutenances[0]['president_jury'] ??
                                '–'),
                      ],
                    )
                        : _buildEmptyCard(
                        'Aucune soutenance programmée',
                        Icons.event_outlined),
                    const SizedBox(height: 10),
                    // Notifications récentes
                    _buildSection(
                      'NOTIFICATIONS RÉCENTES',
                      notifs.isEmpty
                          ? [_buildInfoRow('', 'Aucune notification')]
                          : notifs
                          .take(3)
                          .map<Widget>((n) => _buildInfoRow(
                        n['titre'] ?? '',
                        n['message'] ?? '',
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () =>
        const Scaffold(
            body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
            body: Center(child: Text('Erreur: $e'))),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, UtilisateurModel u, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 160,
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
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(u.initiales,
                        style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.nomComplet,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w500)),
                        Text('INE: ${u.ine ?? '–'}',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11)),
                        Text(u.ecoleDoctorale ?? 'UJKZ',
                            style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  // Toggle actif/inactif
                  Column(
                    children: [
                      Switch(
                        value: u.actif,
                        activeColor: Colors.white,
                        activeTrackColor:
                        Colors.white.withOpacity(0.5),
                        onChanged: (val) async {
                          await AdminService()
                              .toggleActifUtilisateur(u.id, val);
                          ref.invalidate(
                              profilDoctorantProvider(doctorantId));
                        },
                      ),
                      Text(u.actif ? 'Actif' : 'Inactif',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String titre, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF4A7A4A),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          ...children,
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
          if (label.isNotEmpty)
            SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textGray,
                      fontWeight: FontWeight.w500)),
            ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 10),
          Text(message,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textGray)),
        ],
      ),
    );
  }
}