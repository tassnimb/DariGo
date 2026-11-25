
import 'package:flutter/material.dart';
import '../../services/reservation_service.dart';

class GestionReservationsScreen extends StatefulWidget {
  const GestionReservationsScreen({super.key});

  @override
  State<GestionReservationsScreen> createState() =>
      _GestionReservationsScreenState();
}

class _GestionReservationsScreenState
    extends State<GestionReservationsScreen> {
  List<Map<String, dynamic>> reservations = [];
  bool chargement = true;
  String? erreur;

  static const String serveurUrl = 'http://127.0.0.1:8000';

  @override
  void initState() {
    super.initState();
    chargerReservations();
  }

  Future<void> chargerReservations() async {
    try {
      final data = await ReservationService.getReservations();

      if (!mounted) return;

      setState(() {
        reservations = data;
        chargement = false;
        erreur = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        erreur = e.toString();
        chargement = false;
      });
    }
  }

  Future<void> changerStatut(int id, String statut) async {
    try {
      await ReservationService.updateStatut(
        reservationId: id,
        statut: statut,
      );

      await chargerReservations();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            statut == 'acceptee'
                ? 'Réservation acceptée.'
                : 'Réservation refusée.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  String valeur(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Non renseigné';
    }
    return value.toString();
  }

  String traduireStatut(String statut) {
    switch (statut) {
      case 'acceptee':
        return 'Acceptée';
      case 'refusee':
        return 'Refusée';
      default:
        return 'En attente';
    }
  }

  String? obtenirPhotoUrl(dynamic photo) {
    if (photo == null || photo.toString().isEmpty) {
      return null;
    }

    String url = photo.toString();

    // URL déjà complète
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // URL relative
    if (!url.startsWith('/')) {
      url = '/$url';
    }

    return '$serveurUrl$url';
  }

  Widget afficherPhoto(dynamic photo) {
    final photoUrl = obtenirPhotoUrl(photo);

    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.deepPurple,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: photoUrl == null
            ? Container(
                color: Colors.deepPurple.shade50,
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.deepPurple,
                ),
              )
            : Image.network(
                photoUrl,
                width: 75,
                height: 75,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.deepPurple.shade50,
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.deepPurple,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget ligneDetail(String titre, dynamic contenu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        '$titre : ${valeur(contenu)}',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des réservations'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: chargement
          ? const Center(child: CircularProgressIndicator())
          : erreur != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(erreur!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            chargement = true;
                          });
                          chargerReservations();
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : reservations.isEmpty
                  ? const Center(
                      child: Text('Aucune réservation reçue.'),
                    )
                  : RefreshIndicator(
                      onRefresh: chargerReservations,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: reservations.length,
                        itemBuilder: (context, index) {
                          final r = reservations[index];
                          final statut = valeur(r['statut']);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    valeur(r['logement_titre']),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  // PHOTO ET INFORMATIONS DU VISITEUR
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      afficherPhoto(r['visiteur_photo']),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              valeur(
                                                r['visiteur_username'],
                                              ),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              valeur(
                                                r['visiteur_email'],
                                              ),
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              valeur(
                                                r['visiteur_phone'],
                                              ),
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Divider(height: 25),

                                  ligneDetail(
                                    'Arrivée',
                                    r['date_arrivee'],
                                  ),
                                  ligneDetail(
                                    'Départ',
                                    r['date_depart'],
                                  ),
                                  ligneDetail(
                                    'Personnes',
                                    r['nombre_personnes'],
                                  ),
                                  ligneDetail(
                                    'Besoins',
                                    r['besoins'],
                                  ),
                                  ligneDetail(
                                    'Message',
                                    r['message'],
                                  ),

                                  const SizedBox(height: 10),

                                  Text(
                                    'Statut : ${traduireStatut(statut)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  if (statut == 'en_attente') ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                changerStatut(
                                              r['id'] as int,
                                              'acceptee',
                                            ),
                                            style:
                                                ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.green,
                                              foregroundColor:
                                                  Colors.white,
                                            ),
                                            child:
                                                const Text('Accepter'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                changerStatut(
                                              r['id'] as int,
                                              'refusee',
                                            ),
                                            style:
                                                ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor:
                                                  Colors.white,
                                            ),
                                            child:
                                                const Text('Refuser'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
