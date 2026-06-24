import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../models/soutenance_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class GestionSoutenancesScreen extends ConsumerWidget {
  const GestionSoutenancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soutenancesAsync = ref.watch(soutenancesAdminProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des Soutenances'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () =>
                _showAjouterSoutenance(context, ref),
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
                    _showAjouterSoutenance(context, ref),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor),
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
        loading: () =>
        const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAjouterSoutenance(context, ref),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSoutenanceCard(SoutenanceModel s) {
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
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    Text('${s.heure} — ${s.lieu}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textGray)),
                  ],
                ),
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

  void _showAjouterSoutenance(BuildContext context, WidgetRef ref) {
    final theseIdCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final heureCtrl = TextEditingController();
    final lieuCtrl = TextEditingController();
    final presidentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
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
            const Text('Programmer une soutenance',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            CustomTextField(
                controller: dateCtrl,
                hintText: 'Date (YYYY-MM-DD)',
                prefixIcon: Icons.calendar_today_outlined),
            const SizedBox(height: 10),
            CustomTextField(
                controller: heureCtrl,
                hintText: 'Heure (ex: 09:00)',
                prefixIcon: Icons.access_time_outlined),
            const SizedBox(height: 10),
            CustomTextField(
                controller: lieuCtrl,
                hintText: 'Lieu (ex: Amphi C - UJKZ)',
                prefixIcon: Icons.location_on_outlined),
            const SizedBox(height: 10),
            CustomTextField(
                controller: presidentCtrl,
                hintText: 'Président du jury',
                prefixIcon: Icons.person_outlined),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Programmer',
              onPressed: () async {
                try {
                  await ref
                      .read(adminServiceProvider)
                      .programmerSoutenance(
                    theseId: 'temp',
                    date: dateCtrl.text,
                    heure: heureCtrl.text,
                    lieu: lieuCtrl.text,
                    presidentJury: presidentCtrl.text,
                  );
                  ref.invalidate(soutenancesAdminProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}