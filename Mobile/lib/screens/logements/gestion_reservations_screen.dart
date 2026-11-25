
import 'package:flutter/material.dart';
import '../../services/reservation_service.dart';
import '../../widgets/custom_popup.dart';

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

  final Set<int> reservationsEnCours = {};

  static const String serveurUrl = 'http://127.0.0.1:8000';

  @override
  void initState() {
    super.initState();
    chargerReservations();
  }

  Future<void> chargerReservations() async {
    if (mounted) {
      setState(() {
        chargement = true;
        erreur = null;
      });
    }

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

      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Erreur de chargement',
        message:
            'Impossible de récupérer les réservations. Vérifiez votre connexion.',
      );
    }
  }

  Future<void> changerStatut(int id, String statut) async {
    if (reservationsEnCours.contains(id)) return;

    final bool accepter = statut == 'acceptee';

    final confirmer = await CustomPopup.showConfirmPopup(
      context: context,
      title: accepter
          ? 'Accepter la réservation ?'
          : 'Refuser la réservation ?',
      message: accepter
          ? 'Voulez-vous vraiment accepter cette réservation ?'
          : 'Voulez-vous vraiment refuser cette réservation ?',
      confirmText: accepter ? 'Accepter' : 'Refuser',
      cancelText: 'Annuler',
    );

    if (!confirmer || !mounted) return;

    setState(() {
      reservationsEnCours.add(id);
    });

    try {
      await ReservationService.updateStatut(
        reservationId: id,
        statut: statut,
      );

      await chargerReservations();

      if (!mounted) return;

      await CustomPopup.showSuccessPopup(
        context: context,
        title: accepter
            ? 'Réservation acceptée !'
            : 'Réservation refusée',
        message: accepter
            ? 'La réservation a été acceptée avec succès.'
            : 'La réservation a été refusée.',
      );
    } catch (e) {
      if (!mounted) return;

      await CustomPopup.showErrorPopup(
        context: context,
        title: 'Modification impossible',
        message:
            'Une erreur est survenue lors de la modification de la réservation.',
      );

      debugPrint('Erreur changement statut : $e');
    } finally {
      if (mounted) {
        setState(() {
          reservationsEnCours.remove(id);
        });
      }
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

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

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
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : erreur != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Impossible de charger les réservations.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: chargerReservations,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : reservations.isEmpty
                  ? RefreshIndicator(
                      onRefresh: chargerReservations,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 200),
                          Center(
                            child: Text(
                              'Aucune réservation reçue.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: chargerReservations,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: reservations.length,
                        itemBuilder: (context, index) {
                          final r = reservations[index];
                          final statut = valeur(r['statut']);
                          final int id = r['id'] as int;
                          final bool enCours =
                              reservationsEnCours.contains(id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
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
                                              valeur(r['visiteur_email']),
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              valeur(r['visiteur_phone']),
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

                                  ligneDetail('Arrivée', r['date_arrivee']),
                                  ligneDetail('Départ', r['date_depart']),
                                  ligneDetail(
                                    'Personnes',
                                    r['nombre_personnes'],
                                  ),
                                  ligneDetail('Besoins', r['besoins']),
                                  ligneDetail('Message', r['message']),

                                  const SizedBox(height: 10),

                                  Text(
                                    'Statut : ${traduireStatut(statut)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: statut == 'acceptee'
                                          ? Colors.green
                                          : statut == 'refusee'
                                              ? Colors.red
                                              : Colors.orange,
                                    ),
                                  ),

                                  if (statut == 'en_attente') ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: enCours
                                                ? null
                                                : () => changerStatut(
                                                      id,
                                                      'acceptee',
                                                    ),
                                            style:
                                                ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.green,
                                              foregroundColor:
                                                  Colors.white,
                                            ),
                                            child: enCours
                                                ? const SizedBox(
                                                    height: 18,
                                                    width: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : const Text('Accepter'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: enCours
                                                ? null
                                                : () => changerStatut(
                                                      id,
                                                      'refusee',
                                                    ),
                                            style:
                                                ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor:
                                                  Colors.white,
                                            ),
                                            child: const Text('Refuser'),
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
