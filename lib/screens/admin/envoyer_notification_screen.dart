import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../services/admin_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class EnvoyerNotificationScreen extends ConsumerStatefulWidget {
  const EnvoyerNotificationScreen({super.key});

  @override
  ConsumerState<EnvoyerNotificationScreen> createState() =>
      _EnvoyerNotificationScreenState();
}

class _EnvoyerNotificationScreenState
    extends ConsumerState<EnvoyerNotificationScreen> {
  final _titreController = TextEditingController();
  final _messageController = TextEditingController();
  String _cible = 'tous';
  String? _ecoleDoctorale;
  bool _isLoading = false;

  final List<Map<String, String>> _cibles = [
    {'value': 'tous', 'label': 'Tous les utilisateurs'},
    {'value': 'doctorant', 'label': 'Tous les doctorants'},
    {'value': 'directeur', 'label': 'Tous les directeurs'},
    {'value': 'csi', 'label': 'Tous les membres CSI'},
    {'value': 'rapporteur', 'label': 'Tous les rapporteurs'},
  ];

  final List<String> _ecoles = ['EDS', 'EDLESHC', 'EDST'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Envoyer une notification'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Destinataires',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor)),
                  const SizedBox(height: 8),
                  // Cibles
                  ..._cibles.map((c) => RadioListTile<String>(
                    value: c['value']!,
                    groupValue: _cible,
                    activeColor: AppTheme.primaryColor,
                    contentPadding: EdgeInsets.zero,
                    title: Text(c['label']!,
                        style: const TextStyle(fontSize: 13)),
                    onChanged: (v) =>
                        setState(() => _cible = v!),
                  )),
                  // Filtre école doctorale
                  if (_cible == 'doctorant') ...[
                    const Text('Filtrer par École Doctorale',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String?>(
                      value: _ecoleDoctorale,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FBF8),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Toutes les écoles')),
                        ..._ecoles.map((e) => DropdownMenuItem(
                            value: e, child: Text(e))),
                      ],
                      onChanged: (v) =>
                          setState(() => _ecoleDoctorale = v),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('Titre *',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor)),
                  const SizedBox(height: 6),
                  CustomTextField(
                    controller: _titreController,
                    hintText: 'Objet de la notification',
                    prefixIcon: Icons.title,
                  ),
                  const SizedBox(height: 14),
                  const Text('Message *',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor)),
                  const SizedBox(height: 6),
                  CustomTextField(
                    controller: _messageController,
                    hintText: 'Contenu de la notification...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Envoyer la notification',
                    isLoading: _isLoading,
                    onPressed: _envoyer,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _envoyer() async {
    if (_titreController.text.isEmpty ||
        _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Remplissez le titre et le message')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AdminService().envoyerNotification(
        titre: _titreController.text,
        message: _messageController.text,
        cible: _cible,
        ecoleDoctorale: _ecoleDoctorale,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification envoyée avec succès !'),
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
}