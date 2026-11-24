import 'package:flutter/material.dart';

import '../../services/favori_service.dart';

class MesFavorisScreen extends StatefulWidget {
  const MesFavorisScreen({super.key});

  @override
  State<MesFavorisScreen> createState() =>
      _MesFavorisScreenState();
}

class _MesFavorisScreenState
    extends State<MesFavorisScreen> {

  static const violet = Color(0xFF6C4AB6);

  late Future<List<Map<String, dynamic>>> favorisFuture;

  @override
  void initState() {
    super.initState();
    chargerFavoris();
  }

  void chargerFavoris() {
    favorisFuture = FavoriService.getFavoris();
  }

  Future<void> actualiser() async {
    setState(() {
      chargerFavoris();
    });

    await favorisFuture;
  }

  Future<void> supprimerFavori(
    int favoriId,
  ) async {

    final confirmer = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Retirer des favoris",
        ),
        content: const Text(
          "Voulez-vous retirer ce logement de vos favoris ?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Non"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text("Oui"),
          ),
        ],
      ),
    );

    if (confirmer != true) {
      return;
    }

    bool success =
        await FavoriService.deleteFavori(
      favoriId,
    );

    if (!mounted) return;

    if (success) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Favori supprimé 💔",
          ),
        ),
      );

      actualiser();

    } else {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Erreur lors de la suppression",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF7F6FA,
      ),
      appBar: AppBar(
        title: const Text(
          "Mes favoris",
        ),
        backgroundColor: violet,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<
          List<Map<String, dynamic>>>(
        future: favorisFuture,
        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erreur : ${snapshot.error}",
              ),
            );
          }

          final favoris =
              snapshot.data ?? [];

          if (favoris.isEmpty) {
            return const Center(
              child: Text(
                "Aucun favori ❤️",
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: actualiser,
            child: ListView.builder(
              padding:
                  const EdgeInsets.all(16),
              itemCount: favoris.length,
              itemBuilder: (
                context,
                index,
              ) {

                final favori =
                    favoris[index];

                return Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 15,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                    ),
                    title: Text(
                      favori[
                              'logement_titre']
                          ?.toString() ??
                          '',
                    ),
                    subtitle: Text(
                      "Ajouté aux favoris",
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        supprimerFavori(
                          favori['id'],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}