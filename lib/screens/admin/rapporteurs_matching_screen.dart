import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../services/admin_service.dart';

class RapporteursMatchingScreen extends ConsumerWidget {
  final String theseId;
  const RapporteursMatchingScreen(
      {super.key, required this.theseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Désigner les rapporteurs'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: AdminService()
            .getRapporteursSuggeresParScore(theseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Aucun rapporteur disponible'));
          }

          final rapporteurs = snapshot.data!;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFF0F7F0),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: AppTheme.primaryColor, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Les rapporteurs sont classés par score de compatibilité avec les mots-clés de la thèse.',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: rapporteurs.length,
                  itemBuilder: (context, index) {
                    final r = rapporteurs[index];
                    final score = r['score'] as int;
                    return _buildRapporteurCard(
                        context, r, score, index);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRapporteurCard(BuildContext context,
      Map<String, dynamic> r, int score, int index) {
    final nom = '${r['prenom']} ${r['nom']}';
    final initiales =
    '${r['prenom']?.toString()[0] ?? ''}${r['nom']?.toString()[0] ?? ''}'
        .toUpperCase();

    Color scoreColor;
    String scoreLabel;
    if (score >= 5) {
      scoreColor = AppTheme.primaryColor;
      scoreLabel = 'Excellent';
    } else if (score >= 3) {
      scoreColor = const Color(0xFF0D47A1);
      scoreLabel = 'Bon';
    } else if (score >= 1) {
      scoreColor = AppTheme.orangeColor;
      scoreLabel = 'Moyen';
    } else {
      scoreColor = Colors.grey;
      scoreLabel = 'Faible';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: index < 2
              ? AppTheme.primaryColor
              : const Color(0xFFDDE8DD),
          width: index < 2 ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scoreColor,
            child: Text(initiales,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(nom,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    if (index < 2) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Recommandé',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9)),
                      ),
                    ],
                  ],
                ),
                Text(
                  r['ecole_doctorale'] ?? '–',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textGray),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Score: $score',
                    style: TextStyle(
                        fontSize: 11,
                        color: scoreColor,
                        fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () async {
                  final dateLimite =
                  DateTime.now().add(const Duration(days: 45));
                  await AdminService().assignerRapporteur(
                    theseId: theseId,
                    rapporteurId: r['id'],
                    dateLimite: dateLimite,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rapporteur assigné !'),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: scoreColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(70, 30),
                ),
                child: const Text('Assigner',
                    style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}