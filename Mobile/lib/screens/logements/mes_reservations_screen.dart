import 'package:flutter/material.dart';
import '../../services/reservation_service.dart';
import '../../services/avis_service.dart';
class MesReservationsScreen extends StatefulWidget {
  const MesReservationsScreen({super.key});

  @override
  State<MesReservationsScreen> createState() =>
      _MesReservationsScreenState();
}

class _MesReservationsScreenState
    extends State<MesReservationsScreen> {

  static const violet = Color(0xFF6C4AB6);

  late Future<List<Map<String, dynamic>>>
      reservationsFuture;

  @override
  void initState() {
    super.initState();
    chargerReservations();
  }

  void chargerReservations() {
    reservationsFuture =
        ReservationService.getReservations();
  }

  Future<void> actualiser() async {
    setState(() {
      chargerReservations();
    });

    await reservationsFuture;
  }

  Color couleurStatut(String statut) {
    switch (statut) {
      case 'acceptee':
        return Colors.green;

      case 'refusee':
        return Colors.red;

      case 'annulee':
        return Colors.grey;

      default:
        return Colors.orange;
    }
  }

  String texteStatut(String statut) {
    switch (statut) {
      case 'acceptee':
        return 'Acceptée';

      case 'refusee':
        return 'Refusée';

      case 'annulee':
        return 'Annulée';

      default:
        return 'En attente';
    }
  }

  Widget afficherInformation(
      IconData icon,
      String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: violet,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texte),
          ),
        ],
      ),
    );
  }

  Widget carteReservation(
      Map<String, dynamic> reservation) {

    final statut =
        reservation['statut']?.toString() ??
            'en_attente';

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Text(
              reservation['logement_titre']
                      ?.toString() ??
                  'Logement',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            afficherInformation(
              Icons.calendar_today,
              'Arrivée : ${reservation['date_arrivee'] ?? '-'}',
            ),

            afficherInformation(
              Icons.calendar_month,
              'Départ : ${reservation['date_depart'] ?? '-'}',
            ),

            afficherInformation(
              Icons.people_outline,
              'Personnes : ${reservation['nombre_personnes'] ?? '-'}',
            ),

            if ((reservation['besoins'] ?? '')
                .toString()
                .isNotEmpty)
              afficherInformation(
                Icons.info_outline,
                'Besoins : ${reservation['besoins']}',
              ),

            if ((reservation['message'] ?? '')
                .toString()
                .isNotEmpty)
              afficherInformation(
                Icons.message_outlined,
                'Message : ${reservation['message']}',
              ),

            const Divider(height: 22),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Statut :',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: couleurStatut(statut)
                        .withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    texteStatut(statut),
                    style: TextStyle(
                      color:
                          couleurStatut(statut),
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

if (statut == 'acceptee')
  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () => donnerAvis(reservation),
      icon: const Icon(Icons.star),
      label: const Text('Donner mon avis'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(14),
      ),
    ),
  ),

if (statut == 'acceptee')
  const SizedBox(height: 10),

            if (statut == 'en_attente')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {

                    final confirmer =
                        await showDialog(
                      context: context,
                      builder: (context) =>
                          AlertDialog(
                        title: const Text(
                          "Confirmation",
                        ),
                        content: const Text(
                          "Voulez-vous annuler cette réservation ?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                false,
                              );
                            },
                            child: const Text(
                              "Non",
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                true,
                              );
                            },
                            child: const Text(
                              "Oui",
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmer != true) {
                      return;
                    }

                    bool success =
                        await ReservationService
                            .updateStatut(
                      reservationId:
                          reservation['id'],
                      statut: 'annulee',
                    );

                    if (!mounted) return;

                    if (success) {

                      ScaffoldMessenger.of(
                              context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Réservation annulée ✅",
                          ),
                        ),
                      );

                      actualiser();

                    } else {

                      ScaffoldMessenger.of(
                              context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Erreur lors de l'annulation ❌",
                          ),
                        ),
                      );
                    }
                  },
                  label: const Text(
                    "Annuler la réservation",
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> donnerAvis(
    Map<String, dynamic> reservation,
  ) async {
    int note = 5;
    final commentaireController = TextEditingController();

    final confirmer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Donner votre avis'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Quelle note donnez-vous ?'),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setDialogState(() {
                              note = index + 1;
                            });
                          },
                          icon: Icon(
                            index < note
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: commentaireController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Votre commentaire',
                        hintText: 'Ex : Très bon logement...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: violet,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Publier'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmer != true || !mounted) {
      commentaireController.dispose();
      return;
    }

    try {
      await AvisService.ajouterAvis(
        reservationId: reservation['id'] as int,
        note: note,
        commentaire: commentaireController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre avis a été publié !'),
          backgroundColor: Colors.green,
        ),
      );

      actualiser();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de publier l’avis : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      commentaireController.dispose();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FA),
      appBar: AppBar(
        title:
            const Text('Mes réservations'),
        backgroundColor: violet,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<
          List<Map<String, dynamic>>>(
        future: reservationsFuture,
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
              child: Text(
                'Erreur : ${snapshot.error}',
              ),
            );
          }

          final reservations =
              snapshot.data ?? [];

          if (reservations.isEmpty) {
            return RefreshIndicator(
              onRefresh: actualiser,
              child: ListView(
                children: const [
                  SizedBox(height: 160),
                  Icon(
                    Icons.event_busy,
                    size: 65,
                    color: violet,
                  ),
                  SizedBox(height: 15),
                  Center(
                    child: Text(
                      'Vous n’avez aucune réservation.',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: actualiser,
            child: ListView.builder(
              padding:
                  const EdgeInsets.all(16),
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                return carteReservation(
                  reservations[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}