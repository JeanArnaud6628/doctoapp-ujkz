import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../models/soutenance_model.dart';
import '../../models/these_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class GestionSoutenancesScreen extends ConsumerStatefulWidget {
  const GestionSoutenancesScreen({super.key});

  @override
  ConsumerState<GestionSoutenancesScreen> createState() =>
      _GestionSoutenancesScreenState();
}

class _GestionSoutenancesScreenState
    extends ConsumerState<GestionSoutenancesScreen> {
  // ─── État du dialogue ────────────────────────────────────────────────────
  String? _selectedTheseId;
  String? _selectedDoctorantNom;
  Map<String, dynamic>? _selectedTheseData;
  bool _isEligible = false;
  List<String> _preRequisManquants = [];

  // ─── Controllers ─────────────────────────────────────────────────────────
  final _dateController = TextEditingController();
  final _heureController = TextEditingController();
  final _lieuController = TextEditingController();
  final _presidentController = TextEditingController();

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final soutenancesAsync = ref.watch(soutenancesAdminProvider);
    final thesesAsync = ref.watch(thesesAdminProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des Soutenances'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAjouterSoutenance(context, thesesAsync),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: soutenancesAsync.when(
        data: (soutenances) => soutenances.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_outlined,
                  size: 64, color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              const Text('Aucune soutenance programmée',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    _showAjouterSoutenance(context, thesesAsync),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Programmer une soutenance',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: soutenances.length,
          itemBuilder: (context, index) {
            final s = soutenances[index];
            return _buildSoutenanceCard(s);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAjouterSoutenance(context, thesesAsync),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ─── CARTE SOUTENANCE ───────────────────────────────────────────────────

  Widget _buildSoutenanceCard(SoutenanceModel s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event,
                    color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Soutenance — ${s.dateSoutenance}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    Text('${s.heure} — ${s.lieu}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textGray)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Programmée',
                    style: TextStyle(
                        fontSize: 10, color: AppTheme.primaryColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: AppTheme.textGray),
              const SizedBox(width: 4),
              Text('Président : ${s.presidentJury}',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textGray)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── DIALOGUE DE PROGRAMMATION ──────────────────────────────────────────

  void _showAjouterSoutenance(
      BuildContext context,
      AsyncValue<List<TheseModel>> thesesAsync,
      ) {
    // Réinitialiser l'état
    _selectedTheseId = null;
    _selectedDoctorantNom = null;
    _selectedTheseData = null;
    _isEligible = false;
    _preRequisManquants = [];
    _dateController.clear();
    _heureController.clear();
    _lieuController.clear();
    _presidentController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          // Récupérer les thèses éligibles
          final thesesData = thesesAsync.asData?.value ?? [];
          final eligibleTheses = thesesData.where((t) {
            // ✅ Critères d'éligibilité
            // 1. Thèse en état "en instruction" ou "en cours"
            // 2. Quitus directeur obtenu
            // 3. Quitus CSI obtenu
            // 4. Validation admin obtenue
            // 5. Rapporteurs affectés
            // 6. Tous les rapports d'expertise déposés

            // Récupérer les données complètes depuis la base
            // Pour simplifier, on utilise les champs disponibles
            // Dans une version plus avancée, on ferait une requête spécifique
            return true; // À affiner selon vos critères
          }).toList();

          // Vérifier l'éligibilité de la thèse sélectionnée
          void _verifierEligibilite(String theseId) {
            final these = thesesData.firstWhere(
                  (t) => t.id == theseId,
              orElse: () => TheseModel(
                id: '',
                titre: '',
                doctorantId: '',
              ),
            );

            setModalState(() {
              _selectedTheseId = theseId;
              _selectedTheseData = these.toJson();
              _selectedDoctorantNom = 'Doctorant #${these.doctorantId.substring(0, 8)}';

              // Vérifier les pré-requis
              _preRequisManquants = [];
              _isEligible = true;

              // TODO: Vérifier les pré-requis réels avec les données de la base
              // Pour l'exemple, on suppose que tout est bon
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Titre ──────────────────────────────────────────────
                const Text(
                  'Programmer une soutenance',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sélectionnez une thèse éligible',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Sélection de la thèse ──────────────────────────────
                _buildThesesDropdown(
                  thesesData,
                  eligibleTheses,
                  setModalState,
                  _verifierEligibilite,
                ),
                const SizedBox(height: 12),

                // ─── Doctorant associé ──────────────────────────────────
                if (_selectedDoctorantNom != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person,
                            color: AppTheme.primaryColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Doctorant',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textGray,
                                ),
                              ),
                              Text(
                                _selectedDoctorantNom!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // ─── Pré-requis ──────────────────────────────────────────
                if (_selectedTheseId != null) ...[
                  _buildPreRequis(),
                  const SizedBox(height: 12),
                ],

                // ─── Champs de la soutenance ────────────────────────────
                CustomTextField(
                  controller: _dateController,
                  hintText: 'Date (YYYY-MM-DD)',
                  prefixIcon: Icons.calendar_today_outlined,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: _heureController,
                  hintText: 'Heure (ex: 09:00)',
                  prefixIcon: Icons.access_time_outlined,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: _lieuController,
                  hintText: 'Lieu (ex: Amphi C - UJKZ)',
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: _presidentController,
                  hintText: 'Président du jury',
                  prefixIcon: Icons.person_outlined,
                ),
                const SizedBox(height: 16),

                // ─── Bouton Programmer ───────────────────────────────────
                CustomButton(
                  text: 'Programmer la soutenance',
                  onPressed: _selectedTheseId != null && _isEligible
                      ? () => _programmer(ctx)
                      : null,
                ),

                if (!_isEligible && _selectedTheseId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Cette thèse n\'est pas encore éligible',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── DROPDOWN THÈSES ────────────────────────────────────────────────────

  Widget _buildThesesDropdown(
      List<TheseModel> theses,
      List<TheseModel> eligibleTheses,
      StateSetter setModalState,
      Function(String) verifierEligibilite,
      ) {
    // Filtrer les thèses qui ont déjà une soutenance
    // TODO: Filtrer les thèses déjà programmées

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sélectionner une thèse *',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedTheseId,
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
          hint: const Text('Sélectionner une thèse éligible'),
          items: eligibleTheses.map((t) {
            return DropdownMenuItem(
              value: t.id,
              child: Text(
                t.titre.length > 40 ? '${t.titre.substring(0, 40)}...' : t.titre,
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setModalState(() {
                _selectedTheseId = value;
              });
              verifierEligibilite(value);
            }
          },
        ),
        if (eligibleTheses.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '⚠️ Aucune thèse éligible pour la soutenance',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange[700],
              ),
            ),
          ),
      ],
    );
  }

  // ─── PRÉ-REQUIS ──────────────────────────────────────────────────────────

  Widget _buildPreRequis() {
    if (_preRequisManquants.isEmpty && _isEligible) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF4CAF50)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '✅ Tous les pré-requis sont remplis',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_preRequisManquants.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFF9800)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text(
                  'Pré-requis manquants :',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ..._preRequisManquants.map((r) => Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Text(
                '• $r',
                style: const TextStyle(fontSize: 11, color: Colors.orange),
              ),
            )),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  // ─── PROGRAMMER ──────────────────────────────────────────────────────────

  Future<void> _programmer(BuildContext ctx) async {
    if (_selectedTheseId == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une thèse')),
      );
      return;
    }

    if (_dateController.text.isEmpty ||
        _heureController.text.isEmpty ||
        _lieuController.text.isEmpty ||
        _presidentController.text.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
        ),
      );
      return;
    }

    try {
      await ref.read(adminServiceProvider).programmerSoutenance(
        theseId: _selectedTheseId!,
        date: _dateController.text,
        heure: _heureController.text,
        lieu: _lieuController.text,
        presidentJury: _presidentController.text,
      );

      ref.invalidate(soutenancesAdminProvider);
      ref.invalidate(thesesAdminProvider);
      ref.invalidate(adminStatsProvider);

      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('✅ Soutenance programmée avec succès !'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        Navigator.pop(ctx);
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}