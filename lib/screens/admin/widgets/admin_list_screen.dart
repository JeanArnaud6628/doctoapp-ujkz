import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/utilisateur_model.dart';

class AdminListScreen extends StatelessWidget {
  final String titre;
  final String role;
  final List<UtilisateurModel> utilisateurs;
  final bool isLoading;
  final String routeAjouter;
  final Function(String) onSupprimer;
  final Function(String) onRecherche;

  const AdminListScreen({
    super.key,
    required this.titre,
    required this.role,
    required this.utilisateurs,
    required this.isLoading,
    required this.routeAjouter,
    required this.onSupprimer,
    required this.onRecherche,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(titre),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push(routeAjouter),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: onRecherche,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search,
                    color: AppTheme.primaryColor),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFC8DFC8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFC8DFC8)),
                ),
              ),
            ),
          ),
          // Badge nombre
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${utilisateurs.length} $titre',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Liste
          Expanded(
            child: isLoading
                ? const Center(
                child: CircularProgressIndicator())
                : utilisateurs.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off_outlined,
                      size: 64,
                      color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  Text('Aucun $titre trouvé',
                      style: const TextStyle(
                          fontSize: 16)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: utilisateurs.length,
              itemBuilder: (context, index) {
                final u = utilisateurs[index];
                return _buildUserCard(context, u);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(routeAjouter),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildUserCard(
      BuildContext context, UtilisateurModel u) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFDDE8DD), width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              u.initiales,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.nomComplet,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                Text(u.email,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textGray)),
                if (u.ine != null)
                  Text('INE: ${u.ine}',
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryColor)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: u.actif
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              u.actif ? 'Actif' : 'Inactif',
              style: TextStyle(
                fontSize: 10,
                color: u.actif
                    ? AppTheme.primaryColor
                    : Colors.red,
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'supprimer') onSupprimer(u.id);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'modifier',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'supprimer',
                child: Row(
                  children: [
                    Icon(Icons.delete_outlined,
                        size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Désactiver',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}