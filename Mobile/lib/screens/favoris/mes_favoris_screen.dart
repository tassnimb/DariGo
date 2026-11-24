
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FA),

      appBar: AppBar(
        title: const Text("Mes favoris"),
        backgroundColor: violet,
        foregroundColor: Colors.white,
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: favorisFuture,
        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erreur : ${snapshot.error}",
              ),
            );
          }

          final favoris = snapshot.data ?? [];

          if (favoris.isEmpty) {
            return const Center(
              child: Text(
                "Aucun favori ❤️",
                style: TextStyle(fontSize: 17),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: actualiser,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoris.length,

              itemBuilder: (context, index) {
                final favori = favoris[index];

                return Card(
                  color: Colors.white,
                  elevation: 2,
                  margin: const EdgeInsets.only(
                    bottom: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),

                    leading: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 30,
                    ),

                    title: Text(
                      favori['logement_titre']
                              ?.toString() ??
                          '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: const Text(
                      "Ajouté aux favoris",
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
