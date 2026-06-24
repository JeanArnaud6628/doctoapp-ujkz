import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_list_screen.dart';

class GestionCSIScreen extends ConsumerStatefulWidget {
  const GestionCSIScreen({super.key});

  @override
  ConsumerState<GestionCSIScreen> createState() =>
      _GestionCSIScreenState();
}

class _GestionCSIScreenState
    extends ConsumerState<GestionCSIScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = _query.isEmpty
        ? ref.watch(csiAdminProvider)
        : ref.watch(rechercheUtilisateurProvider(
        {'query': _query, 'role': 'csi'}));

    return async.when(
      data: (liste) => AdminListScreen(
        titre: 'Membres CSI',
        role: 'csi',
        utilisateurs: liste,
        isLoading: false,
        routeAjouter: AppRoutes.ajouterCSI,
        onSupprimer: (id) async {
          await ref.read(adminServiceProvider).supprimerUtilisateur(id);
          ref.invalidate(csiAdminProvider);
        },
        onRecherche: (q) => setState(() => _query = q),
      ),
      loading: () => AdminListScreen(
        titre: 'Membres CSI',
        role: 'csi',
        utilisateurs: const [],
        isLoading: true,
        routeAjouter: AppRoutes.ajouterCSI,
        onSupprimer: (_) {},
        onRecherche: (_) {},
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erreur: $e')),
      ),
    );
  }
}