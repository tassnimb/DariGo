import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../messagerie/conversations_screen.dart';
import '../favoris/mes_favoris_screen.dart';
import '../../services/favori_service.dart';
import '../../services/logement_service.dart';
import '../../models/logement.dart';

import 'mes_reservations_screen.dart';
import '../login_screen.dart';
import 'ajouter_logement_screen.dart';
import 'logement_detail_screen.dart';
import 'gestion_reservations_screen.dart';

class LogementListScreen extends StatefulWidget {
  const LogementListScreen({super.key});

  @override
  State<LogementListScreen> createState() =>
      _LogementListScreenState();
}

class _LogementListScreenState extends State<LogementListScreen> {
  late Future<List<Logement>> logementsFuture;

  final rechercheController = TextEditingController();

  String role = '';
  String recherche = '';

  RangeValues? selectedRange;
  int ordrePrix = 0;

  // logementId -> favoriId
  final Map<int, int> favoris = {};

  // Évite plusieurs clics pendant une opération.
  final Set<int> favorisEnCours = {};

  bool get isProprietaire => role == 'proprietaire';

  @override
  void initState() {
    super.initState();
    logementsFuture = LogementService.getLogements();
    chargerRole();
  }

  Future<void> chargerRole() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    final nouveauRole =
        (prefs.getString('role') ?? '').toLowerCase();

    setState(() {
      role = nouveauRole;
    });

    if (nouveauRole != 'proprietaire') {
      await chargerFavoris();
    }
  }

  // Récupérer les favoris déjà enregistrés.
  Future<void> chargerFavoris() async {
    try {
      final liste = await FavoriService.getFavoris();

      final Map<int, int> nouveauxFavoris = {};

      for (final favori in liste) {
        final favoriId = favori['id'];
        final logement = favori['logement'];

        int? logementId;

        if (logement is Map) {
          logementId = logement['id'] is num
              ? (logement['id'] as num).toInt()
              : int.tryParse('${logement['id']}');
        } else if (logement is num) {
          logementId = logement.toInt();
        } else {
          logementId = int.tryParse('$logement');
        }

        final id = favoriId is num
            ? favoriId.toInt()
            : int.tryParse('$favoriId');

        if (logementId != null && id != null) {
          nouveauxFavoris[logementId] = id;
        }
      }

      if (!mounted) return;

      setState(() {
        favoris
          ..clear()
          ..addAll(nouveauxFavoris);
      });
    } catch (e) {
      debugPrint('Erreur chargement favoris : $e');
    }
  }

  // Ajouter ou retirer un favori.
  Future<void> toggleFavori(int logementId) async {
    if (favorisEnCours.contains(logementId)) return;

    setState(() {
      favorisEnCours.add(logementId);
    });

    try {
      if (favoris.containsKey(logementId)) {
        final favoriId = favoris[logementId]!;

        final succes =
            await FavoriService.deleteFavori(favoriId);

        if (succes) {
          if (!mounted) return;

          setState(() {
            favoris.remove(logementId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Retiré des favoris'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        final succes =
            await FavoriService.addFavori(logementId);

        if (succes) {
          await chargerFavoris();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ajouté aux favoris ❤️'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la modification du favori : $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          favorisEnCours.remove(logementId);
        });
      }
    }
  }

  void rechargerLogements() {
    setState(() {
      selectedRange = null;
      logementsFuture = LogementService.getLogements();
    });
  }

  Future<void> ouvrirAjout() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AjouterLogementScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      rechargerLogements();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logement ajouté avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  List<Logement> filtrerLogements(
    List<Logement> data,
    RangeValues range,
  ) {
    final resultat = data.where((logement) {
      final texte = recherche.toLowerCase();

      final correspondRecherche =
          logement.titre.toLowerCase().contains(texte) ||
          logement.adresse.toLowerCase().contains(texte);

      final correspondPrix =
          logement.prix >= range.start &&
          logement.prix <= range.end;

      return correspondRecherche && correspondPrix;
    }).toList();

    if (ordrePrix == 1) {
      resultat.sort((a, b) => a.prix.compareTo(b.prix));
    } else if (ordrePrix == 2) {
      resultat.sort((a, b) => b.prix.compareTo(a.prix));
    }

    return resultat;
  }

  void retournerLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    rechercheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const violet = Color(0xFF6C4AB6);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FA),

      appBar: AppBar(
        backgroundColor: violet,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isProprietaire
              ? 'Mes logements'
              : 'Découvrir les logements',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!isProprietaire)
            IconButton(
              tooltip: 'Mes réservations',
              icon: const Icon(Icons.calendar_month),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MesReservationsScreen(),
                  ),
                );
              },
            ),
IconButton(
  tooltip: 'Mes conversations',
  icon: const Icon(Icons.chat_bubble_outline),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ConversationsScreen(),
      ),
    );
  },
),
          if (!isProprietaire)
            IconButton(
              tooltip: 'Mes favoris',
              icon: const Icon(
                Icons.favorite,
                color: Colors.red,
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MesFavorisScreen(),
                  ),
                );

                if (!mounted) return;
                await chargerFavoris();
              },
            ),

          if (isProprietaire)
            IconButton(
              tooltip: 'Gérer les réservations',
              icon: const Icon(Icons.event_note),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const GestionReservationsScreen(),
                  ),
                );
              },
            ),

          IconButton(
            tooltip: 'Déconnexion',
            onPressed: retournerLogin,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      floatingActionButton: isProprietaire
          ? FloatingActionButton.extended(
              onPressed: ouvrirAjout,
              backgroundColor: violet,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            )
          : null,

      body: FutureBuilder<List<Logement>>(
        future: logementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: violet),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 45,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Erreur : ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: rechargerLogements,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return const Center(
              child: Text(
                'Aucun logement disponible',
                style: TextStyle(fontSize: 17),
              ),
            );
          }

          final prix = data.map((e) => e.prix).toList();

          final minPrix = prix.reduce((a, b) => a < b ? a : b);
          final maxPrix = prix.reduce((a, b) => a > b ? a : b);

          final sliderMax =
              maxPrix == minPrix ? minPrix + 1 : maxPrix;

          final range = selectedRange ??
              RangeValues(minPrix, sliderMax);

          final logementsFiltres =
              filtrerLogements(data, range);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final rechercheWidget = TextField(
                      controller: rechercheController,
                      onChanged: (value) {
                        setState(() {
                          recherche = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher un logement...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: violet,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    );

                    final filtreWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Prix (DT)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: violet,
                          ),
                        ),
                        RangeSlider(
                          values: range,
                          min: minPrix,
                          max: sliderMax,
                          divisions: sliderMax > minPrix ? 100 : null,
                          activeColor: violet,
                          labels: RangeLabels(
                            range.start.toStringAsFixed(0),
                            range.end.toStringAsFixed(0),
                          ),
                          onChanged: (values) {
                            setState(() {
                              selectedRange = values;
                            });
                          },
                        ),
                        Text(
                          '${range.start.toStringAsFixed(0)} - '
                          '${range.end.toStringAsFixed(0)} DT',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    );

                    if (constraints.maxWidth >= 600) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: rechercheWidget),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 230,
                            child: filtreWidget,
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        rechercheWidget,
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 230,
                            child: filtreWidget,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${logementsFiltres.length} logement(s)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    DropdownButton<int>(
                      value: ordrePrix,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 0,
                          child: Text('Par défaut'),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Prix croissant'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Prix décroissant'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          ordrePrix = value ?? 0;
                        });
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: logementsFiltres.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun logement ne correspond aux filtres',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          12,
                          4,
                          12,
                          90,
                        ),
                        itemCount: logementsFiltres.length,
                        itemBuilder: (context, index) {
                          final logement = logementsFiltres[index];

                          final estFavori =
                              favoris.containsKey(logement.id);

                          final chargement =
                              favorisEnCours.contains(logement.id);

                          return Card(
                            color: Colors.white,
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                              vertical: 7,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    final result =
                                        await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            LogementDetailScreen(
                                          logement: logement,
                                          isProprietaire:
                                              isProprietaire,
                                        ),
                                      ),
                                    );

                                    if (!mounted) return;

                                    if (result == true) {
                                      rechargerLogements();
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      15,
                                      15,
                                      55,
                                      15,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: violet.withOpacity(0.10),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.home_outlined,
                                            color: violet,
                                            size: 30,
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                logement.titre,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                logement.adresse,
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '${logement.prix.toStringAsFixed(0)} DT',
                                                style: const TextStyle(
                                                  color: violet,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Petit cœur en haut à droite.
                                if (!isProprietaire)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: IconButton(
                                      tooltip: estFavori
                                          ? 'Retirer des favoris'
                                          : 'Ajouter aux favoris',
                                      onPressed: chargement
                                          ? null
                                          : () => toggleFavori(logement.id),
                                      icon: chargement
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              estFavori
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: estFavori
                                                  ? Colors.red
                                                  : Colors.grey,
                                              size: 27,
                                            ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}