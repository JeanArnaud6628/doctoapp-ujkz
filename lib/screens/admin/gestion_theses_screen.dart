import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../models/these_model.dart';

class GestionThesesScreen extends ConsumerWidget {
  const GestionThesesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thesesAsync = ref.watch(thesesAdminProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des Thèses'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: thesesAsync.when(
        data: (theses) => theses.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description_outlined,
                  size: 64, color: AppTheme.primaryColor),
              SizedBox(height: 16),
              Text('Aucune thèse enregistrée',
                  style: TextStyle(fontSize: 16)),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: theses.length,
          itemBuilder: (context, index) {
            final t = theses[index];
            return _buildTheseCard(context, ref, t);
          },
        ),
        loading: () =>
        const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildTheseCard(
      BuildContext context, WidgetRef ref, TheseModel t) {
    Color etatColor;
    switch (t.etat) {
      case 'enregistree':
        etatColor = AppTheme.primaryColor;
        break;
      case 'en cours':
        etatColor = const Color(0xFF0D47A1);
        break;
      case 'en instruction':
        etatColor = const Color(0xFF6A1B9A);
        break;
      case 'soutenue':
        etatColor = const Color(0xFF00695C);
        break;
      default:
        etatColor = AppTheme.textGray;
    }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: etatColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(t.etatLibelle,
                    style:
                    TextStyle(color: etatColor, fontSize: 10)),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  await ref
                      .read(adminServiceProvider)
                      .updateEtatThese(t.id, value);
                  ref.invalidate(thesesAdminProvider);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'en cours',
                      child: Text('En cours')),
                  const PopupMenuItem(
                      value: 'en instruction',
                      child: Text('En instruction')),
                  const PopupMenuItem(
                      value: 'soutenue',
                      child: Text('Soutenue')),
                ],
                child: const Icon(Icons.more_vert,
                    color: AppTheme.textGray),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(t.titre,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (t.specialite != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(t.specialite!,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textGray)),
            ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: t.progression / 100,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(etatColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}