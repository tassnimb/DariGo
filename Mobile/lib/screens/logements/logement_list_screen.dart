import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../messagerie/conversations_screen.dart';
import '../favoris/mes_favoris_screen.dart';

import '../../services/favori_service.dart';
import '../../services/logement_service.dart';
import '../../services/messagerie_service.dart';

import '../../models/logement.dart';

import '../../widgets/custom_popup.dart';

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
  String? profilePhotoUrl;

  RangeValues? selectedRange;
  int ordrePrix = 0;

  // Nombre total de messages non lus.
  int totalMessagesNonLus = 0;

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
    chargerMessagesNonLus();
  }

  // Charger le rôle et la photo de profil.
  Future<void> chargerRole() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    final nouveauRole =
        (prefs.getString('role') ?? '').toLowerCase();

    final photo = prefs.getString('profile_photo');

    setState(() {
      role = nouveauRole;
      profilePhotoUrl = photo;
    });

    if (nouveauRole != 'proprietaire') {
      await chargerFavoris();
    }
  }

  // Charger le nombre total de messages non lus.
  Future<void> chargerMessagesNonLus() async {
    try {
      final liste = await MessagerieService.getConversations();

      int total = 0;

      for (final conversation in liste) {
        if (conversation is! Map) continue;

        final valeur = conversation['messages_non_lus'];

        if (valeur is num) {
          total += valeur.toInt();
        } else {
          total += int.tryParse(
                valeur?.toString() ?? '',
              ) ??
              0;
        }
      }

      if (!mounted) return;

      setState(() {
        totalMessagesNonLus = total;
      });
    } catch (e) {
      debugPrint(
        'Erreur chargement messages non lus : $e',
      );
    }
  }

  // Construire l'icône de messagerie avec son badge.
  Widget construireIconeMessagerie() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(
          Icons.chat_bubble_outline,
          size: 27,
          color: Colors.white,
        ),
        if (totalMessagesNonLus > 0)
          Positioned(
            right: -9,
            top: -8,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 19,
                minHeight: 19,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                totalMessagesNonLus > 99
                    ? '99+'
                    : totalMessagesNonLus.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Ouvrir les conversations et actualiser le badge au retour.
  Future<void> ouvrirConversations() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ConversationsScreen(),
      ),
    );

    if (!mounted) return;

    await chargerMessagesNonLus();
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

          await CustomPopup.showSuccessPopup(
            context: context,
            title: 'Favoris',
            message: 'Logement retiré des favoris.',
          );
        }
      } else {
        final succes =
            await FavoriService.addFavori(logementId);

        if (succes) {
          await chargerFavoris();

          if (!mounted) return;

          await CustomPopup.showSuccessPopup(
            context: context,
            title: 'Favoris',
            message:
                'Logement ajouté aux favoris avec succès !',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Erreur',
        message:
            'Erreur lors de la modification du favori.',
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

  // Ouvrir l'écran d'ajout d'un logement.
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

      await CustomPopup.showSuccessPopup(
        context: context,
        title: 'Logement ajouté',
        message:
            'Votre logement a été ajouté avec succès !',
      );
    }
  }

  // Filtrer et trier les logements.
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
      resultat.sort(
        (a, b) => a.prix.compareTo(b.prix),
      );
    } else if (ordrePrix == 2) {
      resultat.sort(
        (a, b) => b.prix.compareTo(a.prix),
      );
    }

    return resultat;
  }

  // Confirmer la déconnexion.
  Future<void> retournerLogin() async {
    final confirmer = await CustomPopup.showConfirmPopup(
      context: context,
      title: 'Déconnexion',
      message: 'Voulez-vous vraiment vous déconnecter ?',
      confirmText: 'Déconnexion',
      cancelText: 'Annuler',
    );

    if (confirmer) {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
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
                    builder: (_) =>
                        const MesReservationsScreen(),
                  ),
                );
              },
            ),

          // Messagerie avec compteur de messages non lus.
          IconButton(
            tooltip: 'Mes conversations',
            icon: construireIconeMessagerie(),
            onPressed: ouvrirConversations,
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
                    builder: (_) =>
                        const MesFavorisScreen(),
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

          // Photo de profil.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: profilePhotoUrl != null &&
                        profilePhotoUrl!.isNotEmpty
                    ? Image.network(
                        profilePhotoUrl!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            color: violet,
                            size: 25,
                          );
                        },
                      )
                    : const Icon(
                        Icons.person,
                        color: violet,
                        size: 25,
                      ),
              ),
            ),
          ),

          // Déconnexion.
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
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: violet,
              ),
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

          final minPrix =
              prix.reduce((a, b) => a < b ? a : b);

          final maxPrix =
              prix.reduce((a, b) => a > b ? a : b);

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
                        hintText:
                            'Rechercher un logement...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: violet,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    );

                    final filtreWidget = Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
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
                          divisions:
                              sliderMax > minPrix ? 100 : null,
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
                          style:
                              const TextStyle(fontSize: 12),
                        ),
                      ],
                    );

                    if (constraints.maxWidth >= 600) {
                      return Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: rechercheWidget,
                          ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
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
                          final logement =
                              logementsFiltres[index];

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
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                InkWell(
                                  borderRadius:
                                      BorderRadius.circular(16),
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
                                    padding:
                                        const EdgeInsets.fromLTRB(
                                      15,
                                      15,
                                      55,
                                      15,
                                    ),
                                    child: Row(
                                      children: [
                                        // Galerie photos du logement.
                                        _PhotosLogement(
                                          photos: logement.photos,
                                        ),

                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                logement.titre,
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                logement.adresse,
                                                style:
                                                    const TextStyle(
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '${logement.prix.toStringAsFixed(0)} DT',
                                                style:
                                                    const TextStyle(
                                                  color: violet,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Bouton favori.
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
                                          : () => toggleFavori(
                                                logement.id,
                                              ),
                                      icon: chargement
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
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

// ======================================================
// WIDGET GALERIE PHOTOS
// ======================================================

class _PhotosLogement extends StatefulWidget {
  final List<String> photos;

  const _PhotosLogement({
    required this.photos,
  });

  @override
  State<_PhotosLogement> createState() =>
      _PhotosLogementState();
}

class _PhotosLogementState extends State<_PhotosLogement> {
  int photoActuelle = 0;

  @override
  Widget build(BuildContext context) {
    const violet = Color(0xFF6C4AB6);

    if (widget.photos.isEmpty) {
      return Container(
        width: 125,
        height: 110,
        decoration: BoxDecoration(
          color: violet.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.home_outlined,
          color: violet,
          size: 40,
        ),
      );
    }

    return SizedBox(
      width: 125,
      height: 110,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            PageView.builder(
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                setState(() {
                  photoActuelle = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.network(
                  widget.photos[index],
                  width: 125,
                  height: 110,
                  fit: BoxFit.cover,
                  loadingBuilder:
                      (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return Container(
                      color: violet.withOpacity(0.10),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: violet,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder:
                      (context, error, stackTrace) {
                    return Container(
                      color: violet.withOpacity(0.10),
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: violet,
                        size: 35,
                      ),
                    );
                  },
                );
              },
            ),

            // Indicateurs des photos.
            if (widget.photos.length > 1)
              Positioned(
                bottom: 6,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.photos.length,
                    (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 2,
                        ),
                        width: photoActuelle == index ? 8 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: photoActuelle == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.55),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Nombre de photos.
            if (widget.photos.length > 1)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${photoActuelle + 1}/${widget.photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}