import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_list_screen.dart';

class GestionDoctorantsScreen extends ConsumerStatefulWidget {
  const GestionDoctorantsScreen({super.key});

  @override
  ConsumerState<GestionDoctorantsScreen> createState() =>
      _GestionDoctorantsScreenState();
}

class _GestionDoctorantsScreenState
    extends ConsumerState<GestionDoctorantsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = _query.isEmpty
        ? ref.watch(doctorantsProvider)
        : ref.watch(rechercheUtilisateurProvider(
        {'query': _query, 'role': 'doctorant'}));

    return async.when(
      data: (liste) => AdminListScreen(
        titre: 'Doctorants',
        role: 'doctorant',
        utilisateurs: liste,
        isLoading: false,
        routeAjouter: AppRoutes.ajouterDoctorant,
        onSupprimer: (id) async {
          await ref.read(adminServiceProvider).supprimerUtilisateur(id);
          ref.invalidate(doctorantsProvider);
        },
        onRecherche: (q) => setState(() => _query = q),
      ),
      loading: () => AdminListScreen(
        titre: 'Doctorants',
        role: 'doctorant',
        utilisateurs: const [],
        isLoading: true,
        routeAjouter: AppRoutes.ajouterDoctorant,
        onSupprimer: (_) {},
        onRecherche: (_) {},
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erreur: $e')),
      ),
    );
  }
}