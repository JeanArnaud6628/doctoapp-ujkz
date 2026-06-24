import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_list_screen.dart';

class GestionDirecteursScreen extends ConsumerStatefulWidget {
  const GestionDirecteursScreen({super.key});

  @override
  ConsumerState<GestionDirecteursScreen> createState() =>
      _GestionDirecteursScreenState();
}

class _GestionDirecteursScreenState
    extends ConsumerState<GestionDirecteursScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = _query.isEmpty
        ? ref.watch(directeursAdminProvider)
        : ref.watch(rechercheUtilisateurProvider(
        {'query': _query, 'role': 'directeur'}));

    return async.when(
      data: (liste) => AdminListScreen(
        titre: 'Directeurs',
        role: 'directeur',
        utilisateurs: liste,
        isLoading: false,
        routeAjouter: AppRoutes.ajouterDirecteur,
        onSupprimer: (id) async {
          await ref.read(adminServiceProvider).supprimerUtilisateur(id);
          ref.invalidate(directeursAdminProvider);
        },
        onRecherche: (q) => setState(() => _query = q),
      ),
      loading: () => AdminListScreen(
        titre: 'Directeurs',
        role: 'directeur',
        utilisateurs: const [],
        isLoading: true,
        routeAjouter: AppRoutes.ajouterDirecteur,
        onSupprimer: (_) {},
        onRecherche: (_) {},
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erreur: $e')),
      ),
    );
  }
}