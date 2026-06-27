import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/these_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/historique_model.dart';

class HistoriqueScreen extends ConsumerStatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  ConsumerState<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends ConsumerState<HistoriqueScreen> {
  List<HistoriqueModel> _historique = [];
  bool _isLoading = true;
  String _filtre = 'tous';

  final Map<String, Map<String, dynamic>> _typeConfig = {
    'etape': {
      'label': 'Étape',
      'color': AppTheme.primaryColor,
      'icon': Icons.flag_rounded,
    },
    'affectation': {
      'label': 'Affectation',
      'color': const Color(0xFF0D47A1),
      'icon': Icons.people_rounded,
    },
    'validation': {
      'label': 'Validation',
      'color': const Color(0xFF00695C),
      'icon': Icons.verified_rounded,
    },
    'soutenance': {
      'label': 'Soutenance',
      'color': const Color(0xFFC62828),
      'icon': Icons.event_rounded,
    },
    'notification': {
      'label': 'Notification',
      'color': const Color(0xFFE65100),
      'icon': Icons.notifications_rounded,
    },
    'depot': {
      'label': 'Dépôt',
      'color': const Color(0xFF6A1B9A),
      'icon': Icons.upload_file_rounded,
    },
  };

  @override
  void initState() {
    super.initState();
    _chargerHistorique();
  }

  Future<void> _chargerHistorique() async {
    final user = ref.read(authProvider).utilisateur;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('historique')
          .select()
          .eq('utilisateur_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      _historique = (response as List)
          .map((e) => HistoriqueModel.fromJson(e))
          .toList();
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.utilisateur;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theseAsync = ref.watch(theseProvider(user.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mon Historique'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: theseAsync.when(
        data: (these) {
          if (these == null) {
            return _buildErrorState(
              'Vous devez d\'abord enregistrer votre sujet de thèse.',
            );
          }
          return _buildContenu();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildErrorState(
          'Impossible de charger votre thèse.',
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_outlined,
                size: 64, color: AppTheme.orangeColor),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.enregistrerThese),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text(
                'Enregistrer mon sujet',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu() {
    final types = ['tous', ..._typeConfig.keys];
    final filtered = _filtre == 'tous'
        ? _historique
        : _historique.where((h) => h.typeAction == _filtre).toList();

    return Column(
      children: [
        // ─── Filtres ──────────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: types.map((type) {
              final active = _filtre == type;
              final config = _typeConfig[type];
              final label = config != null ? config['label'] : 'Tous';
              final color = config != null ? config['color'] : AppTheme.primaryColor;

              return GestureDetector(
                onTap: () => setState(() => _filtre = type),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? color : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? color : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: active ? Colors.white : Colors.grey,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // ─── Liste ────────────────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final h = filtered[index];
              return _buildHistoriqueItem(h);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text(
            'Aucun historique disponible',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Les actions effectuées apparaîtront ici.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoriqueItem(HistoriqueModel h) {
    final type = h.typeAction ?? 'etape';
    final config = _typeConfig[type] ?? _typeConfig['etape']!;
    final color = config['color'] as Color;
    final icon = config['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.action,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (h.details != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    h.details!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatDate(h.createdAt),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              config['label'] as String,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr).toLocal();
      return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  // ─── BOTTOM NAV ─────────────────────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context, int index) {
    return NavigationBar(
      selectedIndex: index,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE8F5E9),
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go(AppRoutes.dashboard);
            break;
          case 1:
            context.go(AppRoutes.these);
            break;
          case 2:
            context.go(AppRoutes.notifications);
            break;
          case 3:
            context.go(AppRoutes.opportunites);
            break;
          case 4:
            context.go(AppRoutes.profil);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppTheme.primaryColor),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description, color: AppTheme.primaryColor),
          label: 'Thèse',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications, color: AppTheme.primaryColor),
          label: 'Alertes',
        ),
        NavigationDestination(
          icon: Icon(Icons.lightbulb_outlined),
          selectedIcon: Icon(Icons.lightbulb, color: AppTheme.primaryColor),
          label: 'Opportunités',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor),
          label: 'Profil',
        ),
      ],
    );
  }
}