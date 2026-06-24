import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/these_provider.dart';

class TheseScreen extends ConsumerWidget {
  const TheseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const Scaffold();

    final theseAsync = ref.watch(theseProvider(user.id));
    final rapportsAsync = ref.watch(rapportsProvider(user.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Ma Thèse'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: theseAsync.when(
        data: (these) => these == null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.description_outlined,
                  size: 64, color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              const Text('Aucune thèse enregistrée',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    context.push(AppRoutes.enregistrerThese),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor),
                child: const Text('Enregistrer mon projet',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Carte thèse
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFDDE8DD), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            these.etatLibelle,
                            style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(these.titre,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                    if (these.specialite != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(these.specialite!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textGray)),
                      ),
                    if (these.resume != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(these.resume!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textGray),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                      ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: these.progression / 100,
                        backgroundColor: const Color(0xFFE0E0E0),
                        valueColor:
                        const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${these.progression}% complété',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryColor)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Rapports
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFDDE8DD), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('RAPPORTS ANNUELS',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF4A7A4A),
                                fontWeight: FontWeight.w500)),
                        TextButton(
                          onPressed: () =>
                              context.push(AppRoutes.rapports),
                          child: const Text('Voir tout',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor)),
                        ),
                      ],
                    ),
                    rapportsAsync.when(
                      data: (rapports) => rapports.isEmpty
                          ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                            'Aucun rapport déposé',
                            style: TextStyle(
                                color: AppTheme.textGray,
                                fontSize: 12)),
                      )
                          : Column(
                        children: rapports
                            .take(3)
                            .map((r) => ListTile(
                          leading: const Icon(
                              Icons.description,
                              color: AppTheme
                                  .primaryColor),
                          title: Text(
                              'Rapport Année ${r.annee}',
                              style: const TextStyle(
                                  fontSize: 13)),
                          subtitle: Text(
                              r.statutLibelle,
                              style: const TextStyle(
                                  fontSize: 11)),
                        ))
                            .toList(),
                      ),
                      loading: () =>
                      const CircularProgressIndicator(),
                      error: (e, _) => Text('Erreur: $e'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.push(AppRoutes.deposerRapport),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Déposer un rapport'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize:
                        const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Manuscrit
              ElevatedButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.manuscrit),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Déposer le manuscrit final'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        loading: () =>
        const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Widget _buildBottomNav(BuildContext context, int index) {
    return NavigationBar(
      selectedIndex: index,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE8F5E9),
      onDestinationSelected: (i) {
        switch (i) {
          case 0: context.go(AppRoutes.dashboard); break;
          case 1: context.go(AppRoutes.these); break;
          case 2: context.go(AppRoutes.notifications); break;
          case 3: context.go(AppRoutes.opportunites); break;
          case 4: context.go(AppRoutes.profil); break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppTheme.primaryColor), label: 'Accueil'),
        NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description, color: AppTheme.primaryColor), label: 'Thèse'),
        NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications, color: AppTheme.primaryColor), label: 'Alertes'),
        NavigationDestination(icon: Icon(Icons.lightbulb_outlined), selectedIcon: Icon(Icons.lightbulb, color: AppTheme.primaryColor), label: 'Opportunités'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor), label: 'Profil'),
      ],
    );
  }
}