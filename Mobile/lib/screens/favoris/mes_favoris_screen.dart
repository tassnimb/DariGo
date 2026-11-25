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
  static const _fondCreme = Color(0xFFF5F2EB);
  static const _surfaceClaire = Color(0xFFFAF8F3);
  static const _sableClair = Color(0xFFEAE3D5);
  static const _vertSapin = Color(0xFF1F3D2B);
  static const _textePrincipal = Color(0xFF1D2B22);
  static const _texteSecondaire = Color(0xFF677068);
  static const _rougeErreur = Color(0xFFB5483C);

  late Future<List> favorisFuture;

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
      backgroundColor: _fondCreme,

      appBar: AppBar(
        title: const Text(
          "Mes favoris",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _fondCreme,
        foregroundColor: _vertSapin,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      body: FutureBuilder<List>(
        future: favorisFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _vertSapin,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erreur : ${snapshot.error}",
                style: const TextStyle(color: _rougeErreur),
              ),
            );
          }

          final favoris = snapshot.data ?? [];

          if (favoris.isEmpty) {
            return const Center(
              child: Text(
                "Aucun favori ❤️",
                style: TextStyle(
                  fontSize: 17,
                  color: _texteSecondaire,
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: _vertSapin,
            backgroundColor: _surfaceClaire,
            onRefresh: actualiser,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoris.length,
              itemBuilder: (context, index) {
                final favori = favoris[index];

                return Card(
                  color: _surfaceClaire,
                  elevation: 0,
                  margin: const EdgeInsets.only(
                    bottom: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: _sableClair),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _sableClair,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: _rougeErreur,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      favori['logement_titre']
                              ?.toString() ??
                          '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _textePrincipal,
                      ),
                    ),
                    subtitle: const Text(
                      "Ajouté aux favoris",
                      style: TextStyle(color: _texteSecondaire),
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