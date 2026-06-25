import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';

class GestionManuscritsScreen extends ConsumerWidget {
  const GestionManuscritsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manuscritsAsync = ref.watch(manuscritsEnAttenteProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des Manuscrits'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: manuscritsAsync.when(
        data: (manuscrits) => manuscrits.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.upload_file_outlined,
                  size: 64, color: AppTheme.primaryColor),
              SizedBox(height: 16),
              Text('Aucun manuscrit en attente',
                  style: TextStyle(fontSize: 16)),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: manuscrits.length,
          itemBuilder: (context, index) {
            final m = manuscrits[index];
            return _buildManuscritCard(context, ref, m);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildManuscritCard(BuildContext context, WidgetRef ref,
      Map<String, dynamic> m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFDDE8DD), width: 0.5),
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
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.upload_file,
                    color: AppTheme.orangeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['titre'] ?? 'Sans titre',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    Text('Déposé le ${m['date_depot'] ?? '–'}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textGray)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('En attente',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.orangeColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(adminServiceProvider)
                        .rejeterManuscrit(m['id']);
                    ref.invalidate(manuscritsEnAttenteProvider);
                  },
                  icon: const Icon(Icons.close,
                      size: 16, color: Colors.red),
                  label: const Text('Rejeter',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // 🔧 CORRECTION ICI : utilisation de validerManuscritSimple
                    await ref
                        .read(adminServiceProvider)
                        .validerManuscritSimple(m['id']);
                    ref.invalidate(manuscritsEnAttenteProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Manuscrit validé !'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Valider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}