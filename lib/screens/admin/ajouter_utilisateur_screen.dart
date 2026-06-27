import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AjouterUtilisateurScreen extends ConsumerStatefulWidget {
  final String role;
  const AjouterUtilisateurScreen({super.key, required this.role});

  @override
  ConsumerState<AjouterUtilisateurScreen> createState() =>
      _AjouterUtilisateurScreenState();
}

class _AjouterUtilisateurScreenState
    extends ConsumerState<AjouterUtilisateurScreen> {
  // ─── CONTROLLERS COMMUNS ───
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telController = TextEditingController();

  // ─── CONTROLLERS DOCTORANT ───
  final _ineController = TextEditingController();
  final _sexeController = TextEditingController();
  final _dateNaissanceController = TextEditingController();
  final _ecoleController = TextEditingController();
  final _formationController = TextEditingController();
  final _departementController = TextEditingController();
  final _laboratoireController = TextEditingController();
  final _promotionController = TextEditingController();
  final _anneeInscriptionController = TextEditingController();
  final _sujetProvisoireController = TextEditingController();

  bool _isLoading = false;

  final List<String> _ecoles = ['EDS', 'EDLESHC', 'EDST'];
  final List<String> _sexes = ['Masculin', 'Féminin'];

  bool get _isDoctorant => widget.role == 'doctorant';

  String get _titre {
    switch (widget.role) {
      case 'doctorant':
        return 'Ajouter un Doctorant';
      case 'directeur':
        return 'Créer un compte Directeur';
      case 'rapporteur':
        return 'Créer un compte Rapporteur';
      case 'csi':
        return 'Créer un compte Membre CSI';
      default:
        return 'Ajouter un Utilisateur';
    }
  }

  String get _sousTitre {
    if (_isDoctorant) {
      return 'Le doctorant s\'activera lui-même avec son INE';
    }
    return 'Un mot de passe temporaire sera attribué';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_titre),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isDoctorant)
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _importerDoctorants,
              tooltip: 'Importer depuis Excel/CSV',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ─── Message d'information ───
            _buildInfoMessage(),

            // ─── Formulaire ───
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isDoctorant
                        ? 'Informations du doctorant'
                        : 'Informations du compte',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Champs communs ───
                  _buildLabel('Prénom *'),
                  CustomTextField(
                    controller: _prenomController,
                    hintText: 'Prénom',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),

                  _buildLabel('Nom *'),
                  CustomTextField(
                    controller: _nomController,
                    hintText: 'Nom de famille',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),

                  _buildLabel('Email *'),
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'adresse@email.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),

                  _buildLabel('Téléphone'),
                  CustomTextField(
                    controller: _telController,
                    hintText: '+226 XX XX XX XX',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),

                  // ─── Champs DOCTORANT ───
                  if (_isDoctorant) ...[
                    _buildLabel('INE *'),
                    CustomTextField(
                      controller: _ineController,
                      hintText: 'Ex: BF2021XXXXXXXXX',
                      prefixIcon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),

                    _buildLabel('Sexe'),
                    DropdownButtonFormField<String>(
                      value: _sexeController.text.isNotEmpty
                          ? _sexeController.text
                          : null,
                      hint: const Text('Sélectionner le sexe'),
                      items: _sexes.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (v) =>
                          setState(() => _sexeController.text = v ?? ''),
                      decoration: _inputDecoration(),
                    ),
                    const SizedBox(height: 12),

                    _buildLabel('Date de naissance'),
                    CustomTextField(
                      controller: _dateNaissanceController,
                      hintText: 'YYYY-MM-DD',
                      prefixIcon: Icons.calendar_today_outlined,
                    ),
                    const SizedBox(height: 12),

                    _buildLabel('École doctorale *'),
                    DropdownButtonFormField<String>(
                      value: _ecoleController.text.isNotEmpty
                          ? _ecoleController.text
                          : null,
                      hint: const Text('Sélectionner l\'école doctorale'),
                      items: _ecoles.map((e) {
                        return DropdownMenuItem(value: e, child: Text(e));
                      }).toList(),
                      onChanged: (v) =>
                          setState(() => _ecoleController.text = v ?? ''),
                      decoration: _inputDecoration(),
                    ),
                    const SizedBox(height: 12),

                    _buildLabel('Formation doctorale'),
                    CustomTextField(
                      controller: _formationController,
                      hintText: 'Ex: Sciences de la vie',
                      prefixIcon: Icons.school_outlined,
                    ),
                    const SizedBox(height: 12),

                    _buildLabel('Département'),
                    CustomTextField(
                      controller: _departementController,
                      hintText: 'Département d\'appartenance',
                      prefixIcon: Icons.business_outlined,
                    ),
                    const SizedBox(height: 12),

                    _buildLabel('Laboratoire'),
                    CustomTextField(
                      controller: _laboratoireController,
                      hintText: 'Laboratoire de recherche',
                      prefixIcon: Icons.science_outlined,
                    ),
                    const SizedBox(height: 12),

                    _buildLabel('Promotion'),
                    CustomTextField(
                      controller: _promotionController,
                      hintText: 'Ex: Promotion 2022-2023',
                      prefixIcon: Icons.emoji_events_outlined,
                    ),
                    const SizedBox(height: 12),

                    _buildLabel('Année d\'inscription'),
                    CustomTextField(
                      controller: _anneeInscriptionController,
                      hintText: 'Ex: 2022',
                      prefixIcon: Icons.calendar_month_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    _buildLabel('Sujet provisoire de thèse'),
                    CustomTextField(
                      controller: _sujetProvisoireController,
                      hintText: 'Titre provisoire de la thèse',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 16),

                  // ─── Bouton ───
                  CustomButton(
                    text: _isDoctorant
                        ? 'Ajouter le doctorant'
                        : 'Créer le compte',
                    isLoading: _isLoading,
                    onPressed: _creer,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── WIDGETS ─────────────────────────────────────────────────────────────

  Widget _buildInfoMessage() {
    final isDoctorant = _isDoctorant;
    final Color bgColor = isDoctorant
        ? const Color(0xFFE3F2FD)
        : const Color(0xFFFFF3E0);
    final Color borderColor = isDoctorant
        ? const Color(0xFF0D47A1).withOpacity(0.3)
        : const Color(0xFFE65100).withOpacity(0.3);
    final Color iconColor = isDoctorant
        ? const Color(0xFF0D47A1)
        : const Color(0xFFE65100);
    final IconData icon = isDoctorant
        ? Icons.info_outline
        : Icons.lock_outline;

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _sousTitre,
              style: TextStyle(fontSize: 12, color: iconColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
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
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
    );
  }

  // ─── ACTIONS ─────────────────────────────────────────────────────────────

  Future<void> _importerDoctorants() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result == null) return;

      // TODO: Parser le fichier et importer les doctorants
      // Appel à adminService.importerDoctorants(result.files.single.bytes)

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Importation en cours...'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'importation: $e')),
      );
    }
  }

  Future<void> _creer() async {
    // ─── Validation des champs obligatoires ───
    if (_nomController.text.isEmpty ||
        _prenomController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez les champs obligatoires')),
      );
      return;
    }

    if (_isDoctorant && _ineController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L\'INE est obligatoire pour un doctorant')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isDoctorant) {
        // ─── AJOUTER UN DOCTORANT ───
        await ref.read(adminServiceProvider).ajouterDoctorant(
          nom: _nomController.text,
          prenom: _prenomController.text,
          email: _emailController.text,
          ine: _ineController.text,
          telephone: _telController.text.isEmpty ? null : _telController.text,
          sexe: _sexeController.text.isEmpty ? null : _sexeController.text,
          dateNaissance: _dateNaissanceController.text.isEmpty
              ? null
              : _dateNaissanceController.text,
          ecoleDoctorale: _ecoleController.text.isEmpty
              ? null
              : _ecoleController.text,
          formation: _formationController.text.isEmpty
              ? null
              : _formationController.text,
          departement: _departementController.text.isEmpty
              ? null
              : _departementController.text,
          laboratoire: _laboratoireController.text.isEmpty
              ? null
              : _laboratoireController.text,
          promotion: _promotionController.text.isEmpty
              ? null
              : _promotionController.text,
          anneeInscription: _anneeInscriptionController.text.isEmpty
              ? null
              : int.tryParse(_anneeInscriptionController.text),
          sujetProvisoire: _sujetProvisoireController.text.isEmpty
              ? null
              : _sujetProvisoireController.text,
        );

        ref.invalidate(doctorantsProvider);
        ref.invalidate(doctorantsEnAttenteProvider);
        ref.invalidate(adminStatsProvider);
        ref.invalidate(statsDoctorantsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Doctorant ajouté avec succès !'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          context.pop();
        }
      } else {
        // ─── CRÉER UN COMPTE (Directeur, CSI, Rapporteur) ───
        await ref.read(adminServiceProvider).creerUtilisateur(
          nom: _nomController.text,
          prenom: _prenomController.text,
          email: _emailController.text,
          role: widget.role,
          telephone: _telController.text.isEmpty ? null : _telController.text,
        );

        // Invalider les providers
        switch (widget.role) {
          case 'directeur':
            ref.invalidate(directeursAdminProvider);
            break;
          case 'rapporteur':
            ref.invalidate(rapporteursAdminProvider);
            break;
          case 'csi':
            ref.invalidate(csiAdminProvider);
            break;
        }
        ref.invalidate(adminStatsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compte créé avec succès !'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          context.pop();
        }
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