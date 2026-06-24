import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_list_screen.dart';

class GestionRapporteursScreen extends ConsumerStatefulWidget {
  const GestionRapporteursScreen({super.key});

  @override
  ConsumerState<GestionRapporteursScreen> createState() =>
      _GestionRapporteursScreenState();
}

class _GestionRapporteursScreenState
    extends ConsumerState<GestionRapporteursScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = _query.isEmpty
        ? ref.watch(rapporteursAdminProvider)
        : ref.watch(rechercheUtilisateurProvider(
        {'query': _query, 'role': 'rapporteur'}));

    return async.when(
      data: (liste) => AdminListScreen(
        titre: 'Rapporteurs',
        role: 'rapporteur',
        utilisateurs: liste,
        isLoading: false,
        routeAjouter: AppRoutes.ajouterRapporteur,
        onSupprimer: (id) async {
          await ref.read(adminServiceProvider).supprimerUtilisateur(id);
          ref.invalidate(rapporteursAdminProvider);
        },
        onRecherche: (q) => setState(() => _query = q),
      ),
      loading: () => AdminListScreen(
        titre: 'Rapporteurs',
        role: 'rapporteur',
        utilisateurs: const [],
        isLoading: true,
        routeAjouter: AppRoutes.ajouterRapporteur,
        onSupprimer: (_) {},
        onRecherche: (_) {},
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erreur: $e')),
      ),
    );
  }
}